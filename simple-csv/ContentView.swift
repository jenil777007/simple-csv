import SwiftUI
import UniformTypeIdentifiers
import AppKit

// MARK: - Color Theme
extension Color {
    static let background = Color(NSColor.windowBackgroundColor)
    static let secondaryBackground = Color(NSColor.controlBackgroundColor)
    static let text = Color(NSColor.labelColor)
    static let accent = Color(NSColor.controlAccentColor)
    static let border = Color(NSColor.separatorColor)
    static let headerBackground = Color(NSColor.controlAccentColor).opacity(0.1)
}

// MARK: - Constants
enum ViewConstants {
    static let defaultPadding: CGFloat = 8
    static let cellMinWidth: CGFloat = 120
    static let borderWidth: CGFloat = 0.5
    static let cornerRadius: CGFloat = 6
    static let toolbarHeight: CGFloat = 40
    static let buttonSpacing: CGFloat = 12
    static let rowNumberWidth: CGFloat = 40
    static let deleteButtonWidth: CGFloat = 40
}

struct ContentView: View {
    @StateObject private var document = CSVDocument()
    @State private var showingImporter = false
    @State private var showingExporter = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingUnsavedChangesAlert = false
    @State private var editingHeader: Int?
    @State private var headerText = ""
    @FocusState private var isHeaderFocused: Bool
    
    func handleSave() {
        guard document.currentURL != nil && document.hasUnsavedChanges else { return }
        do {
            try document.save()
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
    
    var toolbarView: some View {
        HStack(spacing: ViewConstants.buttonSpacing) {
            Group {
                Button(action: {
                    if document.hasUnsavedChanges {
                        showingUnsavedChangesAlert = true
                    } else {
                        showingImporter = true
                    }
                }) {
                    Label("Open", systemImage: "folder")
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button(action: handleSave) {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(document.currentURL == nil || !document.hasUnsavedChanges)
                
                Button(action: { showingExporter = true }) {
                    Label("Save As", systemImage: "square.and.arrow.down.on.square")
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(document.headers.isEmpty && document.rows.isEmpty)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Divider()
                .frame(height: 20)
                .padding(.horizontal, 4)
            
            Group {
                Button(action: { document.addRow() }) {
                    Label("Add Row", systemImage: "plus.rectangle")
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button(action: { document.addColumn(name: "Column \(document.columnCount + 1)") }) {
                    Label("Add Column", systemImage: "plus.rectangle.on.rectangle")
                }
                .keyboardShortcut("t", modifiers: .command)
            }
            .buttonStyle(.borderless)
            .controlSize(.large)
            
            Spacer()
        }
        .padding(.horizontal)
        .frame(height: ViewConstants.toolbarHeight)
        .background(Color.secondaryBackground)
    }
    
    var tableView: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                // Headers row
                HStack(alignment: .top, spacing: 0) {
                    // Row number header
                    Text("#")
                        .fontWeight(.bold)
                        .frame(width: ViewConstants.rowNumberWidth)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 4)
                        .background(Color.headerBackground)
                        .clipShape(RoundedRectangle(cornerRadius: ViewConstants.cornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: ViewConstants.cornerRadius)
                                .stroke(Color.border, lineWidth: ViewConstants.borderWidth)
                        )
                    
                    // Column headers
                    ForEach(Array(document.headers.enumerated()), id: \.offset) { index, header in
                        HStack(spacing: 4) {
                            if editingHeader == index {
                                TextField("Header", text: $headerText, onCommit: {
                                    document.headers[index] = headerText
                                    document.hasUnsavedChanges = true
                                    editingHeader = nil
                                })
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: ViewConstants.cellMinWidth)
                                .focused($isHeaderFocused)
                                .onSubmit {
                                    document.headers[index] = headerText
                                    document.hasUnsavedChanges = true
                                    editingHeader = nil
                                }
                                .onExitCommand {
                                    editingHeader = nil
                                }
                            } else {
                                Text(header)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .frame(width: ViewConstants.cellMinWidth, alignment: .leading)
                                    .onTapGesture(count: 2) {
                                        editingHeader = index
                                        headerText = header
                                    }
                            }
                            
                            Button(action: { document.deleteColumn(at: index) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                                    .imageScale(.small)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 4)
                        .background(Color.headerBackground)
                        .clipShape(RoundedRectangle(cornerRadius: ViewConstants.cornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: ViewConstants.cornerRadius)
                                .stroke(Color.border, lineWidth: ViewConstants.borderWidth)
                        )
                    }
                    
                    // Delete button column header (empty)
                    Color.clear
                        .frame(width: ViewConstants.deleteButtonWidth)
                }
                .padding(.bottom, 2)
                
                // Data rows
                ForEach(Array(document.rows.enumerated()), id: \.element.id) { rowIndex, row in
                    HStack(alignment: .center, spacing: 0) {
                        // Row number
                        Text("\(rowIndex + 1)")
                            .frame(width: ViewConstants.rowNumberWidth)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 4)
                            .background(Color.background)
                            .clipShape(RoundedRectangle(cornerRadius: ViewConstants.cornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: ViewConstants.cornerRadius)
                                    .stroke(Color.border, lineWidth: ViewConstants.borderWidth)
                            )
                        
                        // Row cells
                        ForEach(Array(row.cells.enumerated()), id: \.offset) { colIndex, cell in
                            DataCell(
                                text: Binding(
                                    get: { cell },
                                    set: { newValue in
                                        if let rowIndex = document.rows.firstIndex(where: { $0.id == row.id }) {
                                            document.updateCell(row: rowIndex, column: colIndex, value: newValue)
                                        }
                                    }
                                ),
                                width: ViewConstants.cellMinWidth
                            )
                        }
                        
                        // Delete row button
                        Button(action: {
                            if let index = document.rows.firstIndex(where: { $0.id == row.id }) {
                                document.deleteRow(at: index)
                            }
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .imageScale(.medium)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: ViewConstants.deleteButtonWidth)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.background)
    }
    
    var statusBar: some View {
        HStack(spacing: ViewConstants.defaultPadding) {
            Label("\(document.rowCount) rows", systemImage: "list.bullet")
            Label("\(document.columnCount) columns", systemImage: "table")
            if document.hasUnsavedChanges {
                Label("Unsaved Changes", systemImage: "exclamationmark.circle")
                    .foregroundColor(.red)
            }
            Spacer()
        }
        .padding(.horizontal)
        .frame(height: ViewConstants.toolbarHeight)
        .background(Color.secondaryBackground)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            toolbarView
            Divider()
            tableView
            Divider()
            statusBar
        }
        .keyboardShortcut("s", modifiers: .command)
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command) && event.characters?.lowercased() == "s" {
                    handleSave()
                    return nil
                }
                return event
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                do {
                    try document.loadCSV(from: url)
                } catch {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            case .failure(let error):
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: CSVFileDocument(csvDocument: document),
            contentType: .commaSeparatedText,
            defaultFilename: "Untitled.csv"
        ) { result in
            if case .failure(let error) = result {
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $showingUnsavedChangesAlert) {
            Alert(
                title: Text("Unsaved Changes"),
                message: Text("Do you want to save your changes before opening a new file?"),
                primaryButton: .default(Text("Save")) {
                    do {
                        try document.save()
                        showingImporter = true
                    } catch {
                        alertMessage = error.localizedDescription
                        showingAlert = true
                    }
                },
                secondaryButton: .destructive(Text("Don't Save")) {
                    showingImporter = true
                }
            )
        }
    }
}

struct DataCell: View {
    @Binding var text: String
    @State private var isEditing = false
    let width: CGFloat
    
    var body: some View {
        TextField("", text: $text, onEditingChanged: { editing in
            isEditing = editing
        })
        .textFieldStyle(PlainTextFieldStyle())
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .frame(width: width)
        .background(isEditing ? Color.accent.opacity(0.1) : Color.background)
        .clipShape(RoundedRectangle(cornerRadius: ViewConstants.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: ViewConstants.cornerRadius)
                .stroke(isEditing ? Color.accent : Color.border, lineWidth: ViewConstants.borderWidth)
        )
    }
}
