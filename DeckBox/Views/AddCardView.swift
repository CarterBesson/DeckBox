// MARK: - Add Card View
/// View for adding new cards to the library.
/// Provides a form for entering card names and fetches card data from an external service.
/// Currently supports Scryfall as the data source.

import SwiftUI
import SwiftData

struct AddCardView: View {
    /// SwiftData model context for database operations
    @Environment(\.modelContext) private var context
    
    /// Environment value to dismiss the view
    @Environment(\.dismiss) private var dismiss

    /// Binding to the newly added card for navigation
    @Binding var newlyAddedCard: Card?

    // MARK: - View State
    
    /// Name of the card to add
    @State private var cardName = ""
    
    /// Text for bulk upload
    @State private var bulkUploadText = ""
    
    /// Loading state during API requests
    @State private var isLoading = false
    
    /// Error message to display if the card lookup fails
    @State private var errorMsg: String?
    
    /// Progress for bulk upload
    @State private var progress: (current: Int, total: Int)?

    /// Focus state for the card name text field
    @FocusState private var isCardNameFocused: Bool
    
    /// Whether we're in bulk upload mode
    @State private var isBulkMode = false

    /// Service for fetching card data from external APIs
    let service: CardDataService = ScryfallService()

    var body: some View {
        NavigationStack {
            Form {
                // Mode selection
                Section {
                    Picker("Mode", selection: $isBulkMode) {
                        Text("Single Card").tag(false)
                        Text("Bulk Upload").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                
                if isBulkMode {
                    // Bulk upload section
                    Section("Bulk Upload") {
                        TextEditor(text: $bulkUploadText)
                            .frame(height: 200)
                        Text("Enter one card name per line")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if let progress = progress {
                            ProgressView(
                                value: Double(progress.current),
                                total: Double(progress.total)
                            ) {
                                Text("Processing \(progress.current) of \(progress.total)")
                            }
                        }
                    }
                } else {
                    // Single card input section
                    Section("Card Name") {
                        TextField("e.g. Black Lotus", text: $cardName)
                            .autocapitalization(.words)
                            .onSubmit {
                                if !cardName.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading {
                                    Task { await addCard() }
                                }
                            }
                            .submitLabel(.done)
                            .focused($isCardNameFocused)
                    }
                }
                
                // Error message display
                if let error = errorMsg {
                    Section { Text(error).foregroundColor(.red) }
                }
            }
            .navigationTitle("Add Cards")
            .toolbar {
                // Cancel button
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                // Add button with loading state
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            if isBulkMode {
                                await addBulkCards()
                            } else {
                                await addCard()
                            }
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Add")
                        }
                    }
                    .disabled(
                        isLoading || (isBulkMode ? 
                            bulkUploadText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty :
                            cardName.trimmingCharacters(in: .whitespaces).isEmpty)
                    )
                }
            }
            .onAppear {
                isCardNameFocused = !isBulkMode
            }
            .onChange(of: isBulkMode) { _, newValue in
                isCardNameFocused = !newValue
                errorMsg = nil
            }
        }
    }
    
    /// Helper function to find an existing card in the database
    /// - Parameters:
    ///   - name: The name of the card to find
    ///   - setCode: The set code of the card to find
    /// - Returns: The existing card if found, nil otherwise
    private func findExistingCard(name: String, setCode: String) -> Card? {
        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate<Card> { card in
                card.name == name && card.setCode == setCode
            }
        )
        return try? context.fetch(descriptor).first
    }
    
    /// Attempts to add a new card to the library
    /// 1. Fetches card data from the external service
    /// 2. Creates a new Card entity with the fetched data or updates existing one
    /// 3. Inserts the card into the database if it's new
    private func addCard() async {
        isLoading = true
        errorMsg = nil
        do {
            let dto = try await service.fetchCard(named: cardName)
            
            if let existingCard = findExistingCard(name: dto.name, setCode: dto.set) {
                // Card exists, increment quantity
                existingCard.quantity += 1
                newlyAddedCard = existingCard
            } else {
                // Card doesn't exist, create new one
                let card = Card(from: dto, modelContext: context)
                context.insert(card)
                newlyAddedCard = card
            }
            dismiss()
        } catch {
            errorMsg = error.localizedDescription
        }
        isLoading = false
    }
    
    /// Attempts to add multiple cards to the library from bulk input
    /// Respects Scryfall's rate limit and shows progress
    private func addBulkCards() async {
        isLoading = true
        errorMsg = nil
        
        // Split input into lines and filter empty ones
        let cardNames = bulkUploadText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !cardNames.isEmpty else {
            errorMsg = "No valid card names found"
            isLoading = false
            return
        }
        
        progress = (0, cardNames.count)
        var failedCards: [(name: String, error: String)] = []
        
        for (index, name) in cardNames.enumerated() {
            do {
                let dto = try await service.fetchCard(named: name)
                
                if let existingCard = findExistingCard(name: dto.name, setCode: dto.set) {
                    // Card exists, increment quantity
                    existingCard.quantity += 1
                } else {
                    // Card doesn't exist, create new one
                    let card = Card(from: dto, modelContext: context)
                    context.insert(card)
                }
                
                progress = (index + 1, cardNames.count)
                
                // Add a small delay to respect rate limit
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            } catch {
                failedCards.append((name, error.localizedDescription))
            }
        }
        
        // Show summary of failures if any
        if !failedCards.isEmpty {
            errorMsg = "Failed to add \(failedCards.count) cards:\n" + 
                failedCards.map { "• \($0.name): \($0.error)" }.joined(separator: "\n")
        } else {
            dismiss()
        }
        isLoading = false
    }
}

/// Preview provider for AddCardView
/// Uses an in-memory model container for testing
#Preview {
    AddCardView(newlyAddedCard: .constant(nil))
        .modelContainer(for: Card.self, inMemory: true)
}
