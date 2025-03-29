import SwiftUI
import UniformTypeIdentifiers

@available(macOS 11.0, *)
public class CSVFileDocument: ReferenceFileDocument {
    public static var readableContentTypes: [UTType] { [UTType(filenameExtension: "csv")!] }
    public static var writableContentTypes: [UTType] { [UTType(filenameExtension: "csv")!] }
    
    @Published public var csvDocument: CSVDocument
    
    public init(csvDocument: CSVDocument = CSVDocument()) {
        self.csvDocument = csvDocument
    }
    
    public required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CSVError.invalidFormat
        }
        
        let lines = string.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            throw CSVError.invalidFormat
        }
        
        let document = CSVDocument()
        
        // Parse headers
        document.headers = lines[0].components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        document.columnCount = document.headers.count
        
        // Parse data rows
        if lines.count > 1 {
            let rows = lines[1...].map { line in
                let cells = line.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                // Pad row if necessary
                let paddedCells = cells + Array(repeating: "", count: max(0, document.columnCount - cells.count))
                return CSVRow(cells: paddedCells)
            }
            document.rows = rows
            document.rowCount = rows.count
        }
        
        self.csvDocument = document
    }
    
    public func snapshot(contentType: UTType) throws -> Data {
        var content = csvDocument.headers.joined(separator: ",")
        if !csvDocument.rows.isEmpty {
            content += "\n"
            content += csvDocument.rows.map { $0.cells.joined(separator: ",") }.joined(separator: "\n")
        }
        
        guard let data = content.data(using: .utf8) else {
            throw CSVError.invalidFormat
        }
        
        return data
    }
    
    public func fileWrapper(snapshot: Data, configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: snapshot)
    }
}
