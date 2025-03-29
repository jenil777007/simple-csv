import Foundation

enum CSVError: LocalizedError {
    case emptyFile
    case invalidFormat
    case permissionDenied
    case accessError
    case noActiveDocument
    
    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The CSV file is empty"
        case .invalidFormat:
            return "Invalid CSV format"
        case .permissionDenied:
            return "Permission denied. Please check file permissions"
        case .accessError:
            return "Unable to access the file. Please try again"
        case .noActiveDocument:
            return "No file is currently open"
        }
    }
}

struct CSVRow: Identifiable {
    let id = UUID()
    var cells: [String]
}

class CSVDocument: ObservableObject {
    @Published var headers: [String] = []
    @Published var rows: [CSVRow] = []
    @Published var rowCount: Int = 0
    @Published var columnCount: Int = 0
    @Published var currentURL: URL?
    @Published var hasUnsavedChanges: Bool = false
    
    init() {}
    
    func save() throws {
        guard let url = currentURL else {
            throw CSVError.noActiveDocument
        }
        try saveCSV(to: url)
        hasUnsavedChanges = false
    }
    
    func loadCSV(from url: URL) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw CSVError.accessError
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
            
            guard !lines.isEmpty else { throw CSVError.emptyFile }
            
            // Parse headers
            headers = lines[0].components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            columnCount = headers.count
            
            // Parse data rows
            rows = lines[1...].map { line in
                let cells = line.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                // Pad row if necessary
                let paddedCells = cells + Array(repeating: "", count: max(0, columnCount - cells.count))
                return CSVRow(cells: paddedCells)
            }
            rowCount = rows.count
            currentURL = url
            hasUnsavedChanges = false
        } catch let error as NSError {
            if error.domain == NSCocoaErrorDomain && 
               (error.code == NSFileReadNoPermissionError || 
                error.code == NSFileReadUnknownError) {
                throw CSVError.permissionDenied
            }
            throw error
        }
    }
    
    func saveAs(to url: URL) throws {
        try saveCSV(to: url)
        currentURL = url
        hasUnsavedChanges = false
    }
    
    internal func saveCSV(to url: URL) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw CSVError.accessError
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            var content = headers.joined(separator: ",") + "\n"
            content += rows.map { $0.cells.joined(separator: ",") }.joined(separator: "\n")
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch let error as NSError {
            if error.domain == NSCocoaErrorDomain && 
               (error.code == NSFileWriteNoPermissionError || 
                error.code == NSFileWriteUnknownError) {
                throw CSVError.permissionDenied
            }
            throw error
        }
    }
    
    func addRow() {
        rows.append(CSVRow(cells: Array(repeating: "", count: columnCount)))
        rowCount += 1
        hasUnsavedChanges = true
    }
    
    func deleteRow(at index: Int) {
        guard index < rows.count else { return }
        rows.remove(at: index)
        rowCount -= 1
        hasUnsavedChanges = true
    }
    
    func addColumn(name: String) {
        headers.append(name)
        for i in 0..<rows.count {
            rows[i].cells.append("")
        }
        columnCount += 1
        hasUnsavedChanges = true
    }
    
    func deleteColumn(at index: Int) {
        guard index < headers.count else { return }
        headers.remove(at: index)
        for i in 0..<rows.count {
            rows[i].cells.remove(at: index)
        }
        columnCount -= 1
        hasUnsavedChanges = true
    }
    
    func updateCell(row: Int, column: Int, value: String) {
        guard row < rows.count && column < columnCount else { return }
        rows[row].cells[column] = value
        hasUnsavedChanges = true
    }
}
