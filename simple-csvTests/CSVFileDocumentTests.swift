import XCTest
import SwiftUI
import UniformTypeIdentifiers
@testable import simple_csv

final class CSVFileDocumentTests: XCTestCase {
    var document: CSVFileDocument!
    var csvDocument: CSVDocument!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        csvDocument = CSVDocument()
        document = CSVFileDocument(csvDocument: csvDocument)
    }
    
    override func tearDownWithError() throws {
        document = nil
        csvDocument = nil
        try super.tearDownWithError()
    }
    
    func testReadConfiguration() throws {
        // Create test data
        let content = "Header1,Header2\nValue1,Value2\nValue3,Value4"
        let data = content.data(using: .utf8)!
        let configuration = FileDocument.ReadConfiguration(contentType: UTType.commaSeparatedText, file: FileWrapper(regularFileWithContents: data))
        
        // Test document creation
        let testDocument = try CSVFileDocument(configuration: configuration)
        
        XCTAssertEqual(testDocument.csvDocument.headers, ["Header1", "Header2"])
        XCTAssertEqual(testDocument.csvDocument.rows.count, 2)
        XCTAssertEqual(testDocument.csvDocument.rows[0], ["Value1", "Value2"])
        XCTAssertEqual(testDocument.csvDocument.rows[1], ["Value3", "Value4"])
    }
    
    func testWriteConfiguration() throws {
        // Set up test data
        csvDocument.headers = ["Test1", "Test2"]
        csvDocument.rows = [["A", "B"], ["C", "D"]]
        csvDocument.rowCount = 2
        csvDocument.columnCount = 2
        
        // Get file wrapper
        let configuration = FileDocument.WriteConfiguration(contentType: UTType.commaSeparatedText)
        let wrapper = try document.fileWrapper(configuration: configuration)
        
        // Verify content
        let data = wrapper.regularFileContents!
        let content = String(data: data, encoding: .utf8)!
        XCTAssertEqual(content, "Test1,Test2\nA,B\nC,D")
    }
    
    func testEmptyDocument() throws {
        // Create empty data
        let data = Data()
        let configuration = FileDocument.ReadConfiguration(contentType: UTType.commaSeparatedText, file: FileWrapper(regularFileContents: data))
        
        // Test document creation with empty data
        let testDocument = try CSVFileDocument(configuration: configuration)
        
        XCTAssertEqual(testDocument.csvDocument.headers, [String]())
        XCTAssertEqual(testDocument.csvDocument.rows, [[String]]())
        XCTAssertEqual(testDocument.csvDocument.rowCount, 0)
        XCTAssertEqual(testDocument.csvDocument.columnCount, 0)
    }
    
    func testContentTypes() {
        XCTAssertTrue(CSVFileDocument.readableContentTypes.contains(UTType.commaSeparatedText))
        XCTAssertTrue(CSVFileDocument.readableContentTypes.contains(UTType.plainText))
        XCTAssertTrue(CSVFileDocument.writableContentTypes.contains(UTType.commaSeparatedText))
        XCTAssertTrue(CSVFileDocument.writableContentTypes.contains(UTType.plainText))
    }
}
