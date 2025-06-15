// MARK: - Card Group View
/// Main view for managing card groups (decks, cubes, etc.) and their types.
/// Provides functionality for creating, editing, and organizing different types of card collections.

import SwiftUI
import SwiftData

struct CardGroupView: View {
    // MARK: - Properties
    
    /// SwiftData model context for database operations
    @Environment(\.modelContext) private var modelContext
    
    /// All group types in the system, sorted by name
    @Query(sort: \GroupType.name) private var groupTypes: [GroupType]
    
    /// Current edit mode state (active/inactive)
    @State private var editMode = EditMode.inactive
    
    // MARK: - View State
    
    /// Controls visibility of the add group type sheet
    @State private var isAddingType = false
    
    /// Controls visibility of the add group sheet
    @State private var isAddingGroup = false
    
    /// Currently selected group type when adding a new group
    @State private var selectedGroupType: GroupType?
    
    /// Name input for new group
    @State private var newGroupName = ""
    
    /// Name input for new group type
    @State private var newTypeName = ""
    
    /// Icon selection for new group type
    @State private var newTypeIcon = "folder"
    
    /// Group type being edited (if any)
    @State private var editingType: GroupType?
    
    // MARK: - Helper Views
    
    /// Creates the header view for a group type section
    /// - Parameter type: The group type to create the header for
    /// - Returns: A view containing the type's name, icon, and add button
    private func headerView(for type: GroupType) -> some View {
        HStack {
            Label(type.name, systemImage: type.iconName)
                .font(.headline)
            Spacer()
            if editMode == .active {
                Button {
                    editingType = type
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    selectedGroupType = type
                    isAddingGroup = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Body
    
    var body: some View {
        List {
            ForEach(groupTypes) { type in
                Section {
                    // Empty state for groups
                    if type.groups.isEmpty {
                        VStack {
                            Text("No \(type.name) yet")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 16)
                        }
                        .listRowInsets(EdgeInsets())
                        .background(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        // List of groups for this type
                        ForEach(type.groups) { group in
                            NavigationLink(value: group) {
                                HStack {
                                    Label(group.name, systemImage: type.iconName)
                                    Spacer()
                                    Text("\(group.cards.count)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.leading, 20)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    modelContext.delete(group)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    headerView(for: type)
                        .padding(.horizontal, -16)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Groups")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: CardGroup.self) { group in
            CardGroupDetailView(group: group)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .primaryAction) {
                if editMode != .active {
                    Button {
                        isAddingType = true
                    } label: {
                        Label("Add Type", systemImage: "plus")
                    }
                }
            }
        }
        .environment(\.editMode, $editMode)
        .onAppear {
            // Create built-in types if they don't exist
            if groupTypes.isEmpty {
                for type in GroupType.builtInTypes {
                    modelContext.insert(type)
                }
            }
        }
        // MARK: - Add Type Sheet
        .sheet(isPresented: $isAddingType) {
            NavigationStack {
                Form {
                    TextField("Type Name", text: $newTypeName)
                    
                    Picker("Icon", selection: $newTypeIcon) {
                        Label("Folder", systemImage: "folder")
                            .tag("folder")
                        Label("Stack", systemImage: "square.stack")
                            .tag("square.stack")
                        Label("List", systemImage: "list.bullet")
                            .tag("list.bullet")
                        Label("Collection", systemImage: "square.grid.2x2")
                            .tag("square.grid.2x2")
                    }
                }
                .navigationTitle("New Group Type")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            resetNewTypeForm()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            let type = GroupType(name: newTypeName, iconName: newTypeIcon)
                            modelContext.insert(type)
                            resetNewTypeForm()
                        }
                        .disabled(newTypeName.isEmpty)
                    }
                }
            }
        }
        // MARK: - Add Group Sheet
        .sheet(isPresented: $isAddingGroup) {
            NavigationStack {
                Form {
                    TextField("Name", text: $newGroupName)
                }
                .navigationTitle("New \(selectedGroupType?.name.dropLast() ?? "Group")")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            resetNewGroupForm()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            if let type = selectedGroupType {
                                let group = CardGroup(name: newGroupName, type: type)
                                modelContext.insert(group)
                            }
                            resetNewGroupForm()
                        }
                        .disabled(newGroupName.isEmpty)
                    }
                }
            }
        }
        // MARK: - Edit Type Sheet
        .sheet(item: $editingType) { type in
            NavigationStack {
                Form {
                    TextField("Type Name", text: .init(
                        get: { type.name },
                        set: { type.name = $0 }
                    ))
                    
                    Picker("Icon", selection: .init(
                        get: { type.iconName },
                        set: { type.iconName = $0 }
                    )) {
                        Label("Folder", systemImage: "folder")
                            .tag("folder")
                        Label("Stack", systemImage: "square.stack")
                            .tag("square.stack")
                        Label("List", systemImage: "list.bullet")
                            .tag("list.bullet")
                        Label("Collection", systemImage: "square.grid.2x2")
                            .tag("square.grid.2x2")
                    }
                }
                .navigationTitle("Edit Group Type")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            editingType = nil
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            editingType = nil
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Resets the new type form and dismisses the sheet
    private func resetNewTypeForm() {
        newTypeName = ""
        newTypeIcon = "folder"
        isAddingType = false
    }
    
    /// Resets the new group form and dismisses the sheet
    private func resetNewGroupForm() {
        newGroupName = ""
        selectedGroupType = nil
        isAddingGroup = false
    }
}

/// Preview provider for CardGroupView
/// Shows the view within a NavigationStack
#Preview {
    NavigationStack {
        CardGroupView()
    }
    .modelContainer(for: CardGroup.self, inMemory: true)
}
