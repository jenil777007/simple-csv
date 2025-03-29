import XCTest
@testable import simple_csv

final class CSVDocumentTests: XCTestCase {
    var document: CSVDocument!
    var testFileURL: URL!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        document = CSVDocument()
        
        // Create a temporary test file
        let tempDir = FileManager.default.temporaryDirectory
        testFileURL = tempDir.appendingPathComponent("test.csv")
        let testContent = "Header1,Header2\nValue1,Value2\nValue3,Value4"
        try testContent.write(to: testFileURL, atomically: true, encoding: .utf8)
    }
    
    override func tearDownWithError() throws {
        if FileManager.default.fileExists(atPath: testFileURL.path) {
            try FileManager.default.removeItem(at: testFileURL)
        }
        document = nil
        testFileURL = nil
        try super.tearDownWithError()
    }
    
    func testLoadCSV() throws {
        // Load the test file
        try document.loadCSV(from: testFileURL)
        
        // Verify headers and content
        XCTAssertEqual(document.headers, ["Header1", "Header2"])
        XCTAssertEqual(document.rows.count, 2)
        XCTAssertEqual(document.rows[0].cells, ["Value1", "Value2"])
        XCTAssertEqual(document.rows[1].cells, ["Value3", "Value4"])
        XCTAssertEqual(document.rowCount, 2)
        XCTAssertEqual(document.columnCount, 2)
    }
    
    func testSaveCSV() throws {
        // Setup test data
        document.headers = ["Test1", "Test2"]
        document.rows = [
            CSVRow(cells: ["A", "B"]),
            CSVRow(cells: ["C", "D"])
        ]
        document.rowCount = 2
        document.columnCount = 2
        
        let saveURL = FileManager.default.temporaryDirectory.appendingPathComponent("save_test.csv")
        try document.saveCSV(to: saveURL)
        
        // Verify saved content
        let savedContent = try String(contentsOf: saveURL, encoding: .utf8)
        XCTAssertTrue(savedContent.contains("Test1,Test2"))
        XCTAssertTrue(savedContent.contains("A,B"))
        XCTAssertTrue(savedContent.contains("C,D"))
        
        try FileManager.default.removeItem(at: saveURL)
    }
    
    func testAddRow() {
        // Setup initial state
        document.headers = ["Test1", "Test2"]
        document.columnCount = 2
        
        // Test adding a row
        document.addRow()
        
        XCTAssertEqual(document.rowCount, 1)
        XCTAssertEqual(document.rows.count, 1)
        XCTAssertEqual(document.rows[0].cells, ["", ""])
    }
    
    func testDeleteRow() {
        // Setup test data
        document.headers = ["Test1", "Test2"]
        document.rows = [
            CSVRow(cells: ["A", "B"]),
            CSVRow(cells: ["C", "D"]),
            CSVRow(cells: ["E", "F"])
        ]
        document.rowCount = 3
        document.columnCount = 2
        
        // Delete middle row
        document.deleteRow(at: 1)
        
        XCTAssertEqual(document.rowCount, 2)
        XCTAssertEqual(document.rows.count, 2)
        XCTAssertEqual(document.rows[0].cells, ["A", "B"])
        XCTAssertEqual(document.rows[1].cells, ["E", "F"])
    }
    
    func testAddColumn() {
        // Setup test data
        document.headers = ["Test1"]
        document.rows = [
            CSVRow(cells: ["A"]),
            CSVRow(cells: ["B"])
        ]
        document.rowCount = 2
        document.columnCount = 1
        
        // Add new column
        document.addColumn(name: "Test2")
        
        XCTAssertEqual(document.columnCount, 2)
        XCTAssertEqual(document.headers, ["Test1", "Test2"])
        XCTAssertEqual(document.rows[0].cells, ["A", ""])
        XCTAssertEqual(document.rows[1].cells, ["B", ""])
    }
    
    func testDeleteColumn() {
        // Setup test data
        document.headers = ["Test1", "Test2", "Test3"]
        document.rows = [
            CSVRow(cells: ["A", "B", "C"]),
            CSVRow(cells: ["D", "E", "F"])
        ]
        document.rowCount = 2
        document.columnCount = 3
        
        // Delete middle column
        document.deleteColumn(at: 1)
        
        XCTAssertEqual(document.columnCount, 2)
        XCTAssertEqual(document.headers, ["Test1", "Test3"])
        XCTAssertEqual(document.rows[0].cells, ["A", "C"])
        XCTAssertEqual(document.rows[1].cells, ["D", "F"])
    }
    
    func testUpdateCell() {
        // Setup test data
        document.headers = ["Test1", "Test2"]
        document.rows = [
            CSVRow(cells: ["A", "B"]),
            CSVRow(cells: ["C", "D"])
        ]
        document.rowCount = 2
        document.columnCount = 2
        
        // Update cell
        document.updateCell(row: 1, column: 0, value: "Updated")
        
        XCTAssertEqual(document.rows[1].cells[0], "Updated")
    }
    
    func testUpdateHeader() {
        // Setup test data
        document.headers = ["Test1", "Test2", "Test3"]
        document.rows = [
            CSVRow(cells: ["A", "B", "C"]),
            CSVRow(cells: ["D", "E", "F"])
        ]
        document.rowCount = 2
        document.columnCount = 3
        
        // Update header
        document.headers[1] = "Updated Header"
        
        XCTAssertEqual(document.headers, ["Test1", "Updated Header", "Test3"])
        XCTAssertEqual(document.columnCount, 3)
        XCTAssertEqual(document.rows[0].cells, ["A", "B", "C"])
        XCTAssertEqual(document.rows[1].cells, ["D", "E", "F"])
    }
    
    func testLoadEmptyFile() throws {
        // Create empty file
        let emptyFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("empty.csv")
        try "".write(to: emptyFileURL, atomically: true, encoding: .utf8)
        
        XCTAssertThrowsError(try document.loadCSV(from: emptyFileURL)) { error in
            XCTAssertTrue(error is CSVError)
        }
        
        try FileManager.default.removeItem(at: emptyFileURL)
    }
    
    func testSaveWithCurrentURL() throws {
        // Setup test data
        document.headers = ["Test1", "Test2"]
        document.rows = [
            CSVRow(cells: ["A", "B"]),
            CSVRow(cells: ["C", "D"])
        ]
        document.rowCount = 2
        document.columnCount = 2
        
        // Set current URL and save
        document.currentURL = testFileURL
        try document.saveCSV(to: testFileURL)
        
        // Verify content was saved
        let savedContent = try String(contentsOf: testFileURL, encoding: .utf8)
        XCTAssertTrue(savedContent.contains("Test1,Test2"))
        XCTAssertTrue(savedContent.contains("A,B"))
        XCTAssertTrue(savedContent.contains("C,D"))
    }
    
    func testSaveWithNoCurrentURL() {
        XCTAssertNil(document.currentURL)
    }
    
    func testSaveAndReload() throws {
        // Setup initial data
        document.headers = ["Test1", "Test2"]
        document.rows = [
            CSVRow(cells: ["A", "B"]),
            CSVRow(cells: ["C", "D"])
        ]
        document.rowCount = 2
        document.columnCount = 2
        
        // Save to temporary file
        let saveURL = FileManager.default.temporaryDirectory.appendingPathComponent("save_reload_test.csv")
        try document.saveCSV(to: saveURL)
        
        // Create new document and load saved file
        let newDocument = CSVDocument()
        try newDocument.loadCSV(from: saveURL)
        
        // Verify content matches
        XCTAssertEqual(newDocument.headers, document.headers)
        XCTAssertEqual(newDocument.rows.count, document.rows.count)
        XCTAssertEqual(newDocument.columnCount, document.columnCount)
        XCTAssertEqual(newDocument.rowCount, document.rowCount)
        
        // Compare cell contents
        for i in 0..<document.rows.count {
            XCTAssertEqual(newDocument.rows[i].cells, document.rows[i].cells)
        }
        
        try FileManager.default.removeItem(at: saveURL)
    }
}
