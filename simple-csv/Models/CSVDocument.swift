import Foundation

public enum CSVError: LocalizedError {
    case emptyFile
    case invalidFormat
    case permissionDenied
    case accessError
    case noActiveDocument
    
    public var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The file is empty."
        case .invalidFormat:
            return "The file has an invalid format."
        case .permissionDenied:
            return "You don't have the permission to access this file."
        case .accessError:
            return "Failed to access the file."
        case .noActiveDocument:
            return "No active CSV document."
        }
    }
}

public struct CSVRow: Identifiable, Equatable {
    public let id = UUID()
    public var cells: [String]
    
    public init(cells: [String]) {
        self.cells = cells
    }
    
    public static func == (lhs: CSVRow, rhs: CSVRow) -> Bool {
        return lhs.id == rhs.id
    }
}

public class CSVDocument: ObservableObject {
    @Published public var headers: [String] = []
    @Published public var rows: [CSVRow] = []
    @Published public var rowCount: Int = 0
    @Published public var columnCount: Int = 0
    @Published public var currentURL: URL?
    @Published public var hasUnsavedChanges: Bool = false
    
    public init() {}
    
    public func save() throws {
        guard let url = currentURL else {
            throw CSVError.noActiveDocument
        }
        
        try saveCSV(to: url)
        hasUnsavedChanges = false
    }
    
    public func loadCSV(from url: URL) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw CSVError.accessError
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        let content = try String(contentsOf: url, encoding: .utf8)
        let rows = content.components(separatedBy: "\n")
        
        if rows.isEmpty {
            throw CSVError.emptyFile
        }
        
        headers = rows[0].components(separatedBy: ",")
        self.rows = []
        for i in 1..<rows.count {
            let row = rows[i].components(separatedBy: ",")
            self.rows.append(CSVRow(cells: row))
        }
        rowCount = rows.count - 1
        columnCount = headers.count
    }
    
    public func saveAs(to url: URL) throws {
        try saveCSV(to: url)
        currentURL = url
        hasUnsavedChanges = false
    }
    
    public func saveCSV(to url: URL) throws {
        var csvText = ""
        
        let headerLine = headers.joined(separator: ",")
        csvText.append(headerLine + "\n")
        
        for row in rows {
            let rowLine = row.cells.joined(separator: ",")
            csvText.append(rowLine + "\n")
        }
        
        do {
            try csvText.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw CSVError.permissionDenied
        }
    }
    
    public func addRow() {
        rows.append(CSVRow(cells: Array(repeating: "", count: columnCount)))
        rowCount += 1
        hasUnsavedChanges = true
    }
    
    public func deleteRow(at index: Int) {
        guard index < rows.count else { return }
        rows.remove(at: index)
        rowCount -= 1
        hasUnsavedChanges = true
    }
    
    public func addColumn(name: String) {
        headers.append(name)
        for i in 0..<rows.count {
            rows[i].cells.append("")
        }
        columnCount += 1
        hasUnsavedChanges = true
    }
    
    public func deleteColumn(at index: Int) {
        guard index < headers.count else { return }
        headers.remove(at: index)
        for i in 0..<rows.count {
            rows[i].cells.remove(at: index)
        }
        columnCount -= 1
        hasUnsavedChanges = true
    }
    
    public func updateCell(row: Int, column: Int, value: String) {
        guard row < rows.count && column < columnCount else { return }
        rows[row].cells[column] = value
        hasUnsavedChanges = true
    }
}
