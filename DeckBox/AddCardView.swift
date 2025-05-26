//
//  AddCardView.swift
//  DeckBox
//
//  Created by Carter Besson on 5/25/25.
//

import SwiftUI
import SwiftData

struct AddCardView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)    private var dismiss

    @State private var cardName  = ""
    @State private var isLoading = false
    @State private var errorMsg  : String?

    // Our lookup service
    let service: CardDataService = ScryfallService()

    var body: some View {
        NavigationStack {
            Form {
                Section("Card Name") {
                    TextField("e.g. Black Lotus", text: $cardName)
                        .autocapitalization(.words)
                }
                if let error = errorMsg {
                    Section { Text(error).foregroundColor(.red) }
                }
            }
            .navigationTitle("Add a Card")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
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
    
    

    private func addCard() async {
        isLoading = true
        errorMsg  = nil
        do {
            let dto  = try await service.fetchCard(named: cardName)
            let card = Card(from: dto)
            context.insert(card)
            dismiss()
        } catch {
            errorMsg = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    AddCardView()
        .modelContainer(for: Card.self, inMemory: true)
}
