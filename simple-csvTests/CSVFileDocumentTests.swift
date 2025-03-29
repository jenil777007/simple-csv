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
        // Create a test CSV document with known data
        let testCSV = CSVDocument()
        testCSV.headers = ["Header1", "Header2"]
        testCSV.rows = [
            CSVRow(cells: ["Value1", "Value2"]),
            CSVRow(cells: ["Value3", "Value4"])
        ]
        testCSV.rowCount = 2
        testCSV.columnCount = 2
        
        // Create a document with this CSV data
        let testDocument = CSVFileDocument(csvDocument: testCSV)
        
        // Verify the document contains the expected data
        XCTAssertEqual(testDocument.csvDocument.headers, ["Header1", "Header2"])
        XCTAssertEqual(testDocument.csvDocument.rowCount, 2)
        XCTAssertEqual(testDocument.csvDocument.columnCount, 2)
        
        // Verify cell contents are correct
        XCTAssertEqual(testDocument.csvDocument.rows[0].cells, ["Value1", "Value2"])
        XCTAssertEqual(testDocument.csvDocument.rows[1].cells, ["Value3", "Value4"])
    }

    func testWriteConfiguration() throws {
        // Set up test data
        csvDocument.headers = ["Test1", "Test2"]
        csvDocument.rows = [
            CSVRow(cells: ["A", "B"]),
            CSVRow(cells: ["C", "D"])
        ]
        csvDocument.rowCount = 2
        csvDocument.columnCount = 2

        // Create a temporary URL to save the file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-output.csv")
        try csvDocument.saveCSV(to: tempURL)
        
        // Read back the content and verify
        let savedContent = try String(contentsOf: tempURL, encoding: .utf8)
        XCTAssertTrue(savedContent.contains("Test1,Test2"))
        XCTAssertTrue(savedContent.contains("A,B"))
        XCTAssertTrue(savedContent.contains("C,D"))
        
        // Clean up
        try FileManager.default.removeItem(at: tempURL)
    }

    func testEmptyDocument() throws {
        // Create empty file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("empty.csv")
        try "".write(to: tempURL, atomically: true, encoding: .utf8)
        
        // Test loading empty file
        let emptyDocument = CSVDocument()
        XCTAssertThrowsError(try emptyDocument.loadCSV(from: tempURL)) { error in
            XCTAssertTrue(error is CSVError)
        }
        
        // Clean up
        try FileManager.default.removeItem(at: tempURL)
    }
}
