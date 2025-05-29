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

    // MARK: - View State
    
    /// Name of the card to add
    @State private var cardName = ""
    
    /// Loading state during API requests
    @State private var isLoading = false
    
    /// Error message to display if the card lookup fails
    @State private var errorMsg: String?

    /// Service for fetching card data from external APIs
    let service: CardDataService = ScryfallService()

    var body: some View {
        NavigationStack {
            Form {
                // Card name input section
                Section("Card Name") {
                    TextField("e.g. Black Lotus", text: $cardName)
                        .autocapitalization(.words)
                }
                
                // Error message display
                if let error = errorMsg {
                    Section { Text(error).foregroundColor(.red) }
                }
            }
            .navigationTitle("Add a Card")
            .toolbar {
                // Cancel button
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                // Add button with loading state
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await addCard() }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Add")
                        }
                    }
                    .disabled(cardName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                }
            }
        }
    }
    
    /// Attempts to add a new card to the library
    /// 1. Fetches card data from the external service
    /// 2. Creates a new Card entity with the fetched data
    /// 3. Inserts the card into the database
    /// 4. Dismisses the view on success or shows error on failure
    private func addCard() async {
        isLoading = true
        errorMsg = nil
        do {
            let dto = try await service.fetchCard(named: cardName)
            let card = Card(from: dto)
            context.insert(card)
            dismiss()
        } catch {
            errorMsg = error.localizedDescription
        }
        isLoading = false
    }
}

/// Preview provider for AddCardView
/// Uses an in-memory model container for testing
#Preview {
    AddCardView()
        .modelContainer(for: Card.self, inMemory: true)
}
