////
////  CardDetailView.swift
////  DeckBox
////
////  Created by Carter Besson on 5/24/25.
////
//
//// MARK: - Card Detail View
///// Detailed view for a single card, showing its image, metadata, and tags.
///// Allows editing of card quantity and management of tags.
//
//import SwiftUI
//import SwiftData
//
//struct CardDetailView: View {
//    /// The card being displayed and edited
//    @Bindable var card: Card             // SwiftData auto–bindable
//    @Environment(\.modelContext) private var modelContext
//    @Environment(\.colorScheme) private var colorScheme
//    @Environment(\.dismiss) private var dismiss
//    @State private var showingDeleteConfirmation = false
//    @State private var showingTagSheet = false
//    
//    private let shownFormats: [String] = ["standard", "modern", "commander"]
//    
//    private var isDoubleSided: Bool {
//        card.layout == "transform" || card.layout == "modal_dfc" || card.layout == "split"
//    }
//    
//    private var currentFace: CardFace? {
//        guard isDoubleSided, !card.faces.isEmpty else { return nil }
//        return card.faces[0]
//    }
//    
//    // MARK: - View State
//    
//    /// Controls visibility of the add tag sheet
//    @State private var isAddingTag = false
//
//    // MARK: – Body
//
//    var body: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 16) {
//                CardImageSection(card: card)
//                
//                CardMetadataSection(card: card, face: currentFace)
//                
//                Divider()
//                
//                CardAttributesSection(card: card)
//                
//                LegalitiesSection(card: card, shownFormats: shownFormats)
//                
//                Divider()
//                
//                QuantitySection(card: card)
//                
//                // Tags section
//                TagsSection(card: card, colorScheme: colorScheme, onAdd: { isAddingTag = true })
//            }
//            .padding()
//        }
//        .navigationTitle(card.name)
//        .navigationBarTitleDisplayMode(.inline)
//        .sheet(isPresented: $isAddingTag) {
//            AddTagSheet(card: card, isPresented: $isAddingTag)
//        }
//        .toolbar {
//            ToolbarItem(placement: .topBarTrailing) {
//                Menu {
//                    Button(role: .destructive) {
//                        showingDeleteConfirmation = true
//                    } label: {
//                        Label("Delete", systemImage: "trash")
//                    }
//                } label: {
//                    Image(systemName: "ellipsis.circle")
//                }
//            }
//        }
//        .alert("Delete Card", isPresented: $showingDeleteConfirmation) {
//            Button("Cancel", role: .cancel) { }
//            Button("Delete", role: .destructive) {
//                modelContext.delete(card)
//                dismiss()
//            }
//        } message: {
//            Text("Are you sure you want to delete this card?")
//        }
//    }
//}
//
///// Preview provider for CardDetailView
///// Uses an in-memory model container for testing
//#Preview {
//    ContentView()
//        .modelContainer(for: Card.self, inMemory: true)
//}
