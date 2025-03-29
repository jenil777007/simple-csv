import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var commaSeparatedText: UTType {
        UTType.types(tag: "csv",
                    tagClass: .filenameExtension,
                    conformingTo: .text).first ?? .plainText
    }
}

struct CSVFileDocument: FileDocument {
    var csvDocument: CSVDocument
    
    static var readableContentTypes: [UTType] { [.commaSeparatedText, .plainText] }
    static var writableContentTypes: [UTType] { [.commaSeparatedText, .plainText] }
    
    init(csvDocument: CSVDocument) {
        self.csvDocument = csvDocument
    }
    
    init(configuration: ReadConfiguration) throws {
        csvDocument = CSVDocument()
        
        if let data = configuration.file.regularFileContents,
           let string = String(data: data, encoding: .utf8) {
            let lines = string.components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
            
            guard !lines.isEmpty else { return }
            
            // Parse headers
            csvDocument.headers = lines[0].components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            csvDocument.columnCount = csvDocument.headers.count
            
            // Parse data rows
            let rows = lines[1...].map { line in
                let cells = line.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                // Pad row if necessary
                let paddedCells = cells + Array(repeating: "", count: max(0, csvDocument.columnCount - cells.count))
                return CSVRow(cells: paddedCells)
            }
            csvDocument.rows = rows
            csvDocument.rowCount = rows.count
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // Create content directly in memory
        var content = csvDocument.headers.joined(separator: ",") + "\n"
        content += csvDocument.rows.map { $0.cells.joined(separator: ",") }.joined(separator: "\n")
        
        guard let data = content.data(using: .utf8) else {
            throw CSVError.invalidFormat
        }
        
        return .init(regularFileWithContents: data)
    }
}
