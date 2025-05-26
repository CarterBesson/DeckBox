import SwiftUI
import SwiftData

struct TagManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.name) private var allTags: [Tag]
    @State private var isAddingTag = false
    @State private var selectedTag: Tag?
    
    // Available colors for tags
    private let availableColors = [
        "blue", "green", "red", "purple", "orange", "pink", "gray"
    ]
    
    var body: some View {
        List {
            Section {
                ForEach(allTags, id: \.name) { tag in
                    TagRowView(tag: tag)
                        .onTapGesture {
                            selectedTag = tag
                        }
                }
                .onDelete(perform: deleteTags)
            }
        }
        .navigationTitle("Manage Tags")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isAddingTag = true
                } label: {
                    Label("Add Tag", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingTag) {
            TagEditorView(mode: .create)
        }
        .sheet(item: $selectedTag) { tag in
            TagEditorView(mode: .edit(tag))
        }
    }
    
    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(allTags[index])
        }
    }
}

// Helper view for displaying a tag in the list
private struct TagRowView: View {
    let tag: Tag
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.fromName(tag.color))
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading) {
                Text(tag.name)
                    .font(.body)
                if let category = tag.category {
                    Text(category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text("\(tag.cards.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// Color picker component
private struct TagColorPicker: View {
    @Binding var selectedColor: String
    let availableColors: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(availableColors, id: \.self) { colorName in
                    ColorButton(
                        color: Color.fromName(colorName),
                        isSelected: selectedColor == colorName,
                        action: { selectedColor = colorName }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// Color group definition
struct ColorGroup {
    let name: String
    let colors: [(name: String, color: Color)]
}

extension ColorGroup: Identifiable {
    var id: String { name }
}

// Helper function to convert color names to Color objects
private func color(from name: String) -> Color {
    switch name {
    case "mtgWhite": return .mtgWhite
    case "mtgBlue": return .mtgBlue
    case "mtgBlack": return .mtgBlack
    case "mtgRed": return .mtgRed
    case "mtgGreen": return .mtgGreen
    case "azorius": return .azorius
    case "dimir": return .dimir
    case "rakdos": return .rakdos
    case "gruul": return .gruul
    case "selesnya": return .selesnya
    case "orzhov": return .orzhov
    case "izzet": return .izzet
    case "golgari": return .golgari
    case "boros": return .boros
    case "simic": return .simic
    case "artifact": return .artifact
    case "gold": return .gold
    case "colorless": return .colorless
    case "land": return .land
    default: return .mtgBlue
    }
}

// Color group section component
private struct ColorGroupSection: View {
    let group: ColorGroup
    @Binding var selectedColor: String
    
    var body: some View {
        Section(group.name) {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 44))
            ], spacing: 12) {
                ForEach(group.colors, id: \.name) { colorOption in
                    ColorButton(
                        color: colorOption.color,
                        isSelected: selectedColor == colorOption.name,
                        action: { selectedColor = colorOption.name }
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// Color button component
private struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 44, height: 44)
            .overlay(
                Circle()
                    .strokeBorder(isSelected ? Color.primary : Color.clear, lineWidth: 2)
            )
            .shadow(radius: isSelected ? 2 : 0)
            .onTapGesture(perform: action)
    }
}

// View for creating/editing tags
struct TagEditorView: View {
    enum Mode: Equatable {
        case create
        case edit(Tag)
    }
    
    let mode: Mode
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var color = "mtgBlue"
    @State private var category = ""
    
    private let colorGroups = [
        ColorGroup(name: "Mana Colors", colors: [
            ("mtgWhite", .mtgWhite),
            ("mtgBlue", .mtgBlue),
            ("mtgBlack", .mtgBlack),
            ("mtgRed", .mtgRed),
            ("mtgGreen", .mtgGreen)
        ]),
        ColorGroup(name: "Guild Colors", colors: [
            ("azorius", .azorius),
            ("dimir", .dimir),
            ("rakdos", .rakdos),
            ("gruul", .gruul),
            ("selesnya", .selesnya),
            ("orzhov", .orzhov),
            ("izzet", .izzet),
            ("golgari", .golgari),
            ("boros", .boros),
            ("simic", .simic)
        ]),
        ColorGroup(name: "Special", colors: [
            ("artifact", .artifact),
            ("gold", .gold),
            ("colorless", .colorless),
            ("land", .land)
        ])
    ]
    
    init(mode: Mode) {
        self.mode = mode
        if case .edit(let tag) = mode {
            _name = State(initialValue: tag.name)
            _color = State(initialValue: tag.color)
            _category = State(initialValue: tag.category ?? "")
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Tag Details") {
                    TextField("Name", text: $name)
                    TextField("Category (optional)", text: $category)
                }
                
                ForEach(colorGroups) { group in
                    ColorGroupSection(
                        group: group,
                        selectedColor: $color
                    )
                }
            }
            .navigationTitle(mode == .create ? "New Tag" : "Edit Tag")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedCategory = category.trimmingCharacters(in: .whitespaces)
        
        switch mode {
        case .create:
            let tag = Tag(
                name: trimmedName,
                color: color,
                category: trimmedCategory.isEmpty ? nil : trimmedCategory
            )
            modelContext.insert(tag)
            
        case .edit(let tag):
            tag.name = trimmedName
            tag.color = color
            tag.category = trimmedCategory.isEmpty ? nil : trimmedCategory
        }
    }
} 