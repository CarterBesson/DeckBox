// MARK: - Tag Management
/// Views and components for managing tags in the application.
/// Provides functionality for creating, editing, and deleting tags,
/// as well as organizing them by categories and colors.

import SwiftUI
import SwiftData

// MARK: - Tag Management View
/// Main view for managing all tags in the system
/// Displays a list of existing tags and provides options to add, edit, or delete them
struct TagManagementView: View {
    /// SwiftData model context for database operations
    @Environment(\.modelContext) private var modelContext
    
    /// All tags in the system, sorted by name
    @Query(sort: \Tag.name) private var allTags: [Tag]
    
    /// Controls visibility of the add tag sheet
    @State private var isAddingTag = false
    
    /// Currently selected tag for editing
    @State private var selectedTag: Tag?
    
    /// Standard colors available for tag customization
    private let availableColors = [
        "blue", "green", "red", "purple", "orange", "pink", "gray"
    ]
    
    var body: some View {
        List {
            // Group tags by category
            ForEach(Dictionary(grouping: allTags) { $0.category ?? "" }.sorted(by: { $0.key < $1.key }), id: \.key) { category, tags in
                Section(category.isEmpty ? "Uncategorized" : category) {
                    ForEach(tags.sorted(by: { $0.name < $1.name })) { tag in
                        TagRowView(tag: tag)
                            .onTapGesture {
                                selectedTag = tag
                            }
                    }
                    .onDelete { indices in
                        for index in indices {
                            modelContext.delete(tags[index])
                        }
                    }
                }
            }
        }
        .navigationTitle("Tags")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
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
}

#Preview {
    NavigationStack {
        TagManagementView()
    }
    .modelContainer(for: Tag.self, inMemory: true)
}

// MARK: - Tag Row View
/// Helper view for displaying a single tag in the list
/// Shows the tag's color, name, category, and card count
private struct TagRowView: View {
    /// The tag to display
    let tag: Tag
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            // Color indicator
            Circle()
                .fill(Color.fromName(tag.color))
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.tagBorder(colorName: tag.color, colorScheme: colorScheme), lineWidth: 1)
                )
            
            // Tag details
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
            
            // Card count
            Text("\(tag.cards.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Tag Color Picker
/// Horizontal scrolling color picker component
/// Displays available colors as selectable circles
private struct TagColorPicker: View {
    /// Currently selected color name
    @Binding var selectedColor: String
    
    /// Available colors to choose from
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

// MARK: - Color Group Model
/// Represents a group of related colors (e.g., "Mana Colors", "Guild Colors")
struct ColorGroup {
    /// Name of the color group
    let name: String
    
    /// Colors in this group, with their names and Color values
    let colors: [(name: String, color: Color)]
}

extension ColorGroup: Identifiable {
    var id: String { name }
}

// MARK: - Color Utilities
/// Converts color names to SwiftUI Color objects
/// Supports Magic: The Gathering color scheme
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

// MARK: - Color Group Section
/// Displays a grid of colors for a specific color group
private struct ColorGroupSection: View {
    /// The color group to display
    let group: ColorGroup
    
    /// Currently selected color name
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

// MARK: - Color Button
/// Interactive color selection button
/// Displays a color circle with selection state
private struct ColorButton: View {
    /// The color to display
    let color: Color
    
    /// Whether this color is currently selected
    let isSelected: Bool
    
    /// Action to perform when tapped
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

// MARK: - Tag Editor View
/// View for creating new tags or editing existing ones
/// Provides fields for name, category, and color selection
struct TagEditorView: View {
    /// Defines whether we're creating a new tag or editing an existing one
    enum Mode: Equatable {
        case create
        case edit(Tag)
    }
    
    /// Current editing mode
    let mode: Mode
    
    /// SwiftData model context for database operations
    @Environment(\.modelContext) private var modelContext
    
    /// Environment value to dismiss the view
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - View State
    
    /// Tag name input
    @State private var name = ""
    
    /// Selected color name
    @State private var color = "mtgBlue"
    
    /// Optional category input
    @State private var category = ""
    
    /// Controls visibility of duplicate name alert
    @State private var showDuplicateAlert = false
    
    /// Available color groups for tag customization
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
    
    /// Initializes the view with the specified mode
    /// If editing, populates the form with the tag's current values
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
                // Tag details section
                Section("Tag Details") {
                    TextField("Name", text: $name)
                    TextField("Category (optional)", text: $category)
                }
                
                // Color selection sections
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
                        if save() {
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .alert("Duplicate Tag", isPresented: $showDuplicateAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("A tag with that name already exists.")
        }
    }
    
    private func save() -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedCategory = category.trimmingCharacters(in: .whitespaces)
        
        switch mode {
        case .create:
            let allTags = try? modelContext.fetch(FetchDescriptor<Tag>())
            if allTags?.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) == true {
                showDuplicateAlert = true
                return false
            }
            let tag = Tag(
                name: trimmedName,
                color: color,
                category: trimmedCategory.isEmpty ? nil : trimmedCategory
            )
            modelContext.insert(tag)
            return true
            
        case .edit(let tag):
            tag.name = trimmedName
            tag.color = color
            tag.category = trimmedCategory.isEmpty ? nil : trimmedCategory
            return true
        }
    }
}

import SwiftUI
import SwiftData

struct TagPickerView: View {
    @Binding var selectedTags: [Tag]
    @Query(sort: \Tag.name) private var allTags: [Tag]

    var body: some View {
        List {
            ForEach(allTags) { tag in
                Button(action: {
                    if selectedTags.contains(where: { $0.id == tag.id }) {
                        selectedTags.removeAll { $0.id == tag.id }
                    } else {
                        selectedTags.append(tag)
                    }
                }) {
                    HStack {
                        Circle()
                            .fill(Color.fromName(tag.color))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary, lineWidth: 1)
                            )

                        Text(tag.name)
                        Spacer()
                        if selectedTags.contains(where: { $0.id == tag.id }) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Tags")
    }
}
