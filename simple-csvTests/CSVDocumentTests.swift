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
        try super.tearDownWithError()
        // Clean up test file
        if FileManager.default.fileExists(atPath: testFileURL.path) {
            try FileManager.default.removeItem(at: testFileURL)
        }
        document = nil
        testFileURL = nil
    }
    
    func testLoadCSV() throws {
        try document.loadCSV(from: testFileURL)
        
        XCTAssertEqual(document.headers, ["Header1", "Header2"])
        XCTAssertEqual(document.rows.count, 2)
        XCTAssertEqual(document.rows[0].cells, ["Value1", "Value2"])
        XCTAssertEqual(document.rows[1].cells, ["Value3", "Value4"])
        XCTAssertEqual(document.rowCount, 2)
        XCTAssertEqual(document.columnCount, 2)
        XCTAssertFalse(document.hasUnsavedChanges)
    }
    
    func testSaveCSV() throws {
        document.headers = ["Test1", "Test2"]
        document.rows = [
            CSVRow(cells: ["A", "B"]),
            CSVRow(cells: ["C", "D"])
        ]
        document.rowCount = 2
        document.columnCount = 2
        
        let saveURL = FileManager.default.temporaryDirectory.appendingPathComponent("save_test.csv")
        try document.saveCSV(to: saveURL)
        
        let savedContent = try String(contentsOf: saveURL, encoding: .utf8)
        XCTAssertEqual(savedContent, "Test1,Test2\nA,B\nC,D")
        
        try FileManager.default.removeItem(at: saveURL)
    }
    
    func testAddRow() {
        document.headers = ["Test1", "Test2"]
        document.columnCount = 2
        
        document.addRow()
        
        XCTAssertEqual(document.rowCount, 1)
        XCTAssertEqual(document.rows.count, 1)
        XCTAssertEqual(document.rows[0].cells, ["", ""])
        XCTAssertTrue(document.hasUnsavedChanges)
    }
    
    func testDeleteRow() {
        document.headers = ["Test1", "Test2"]
        document.rows = [
            CSVRow(cells: ["A", "B"]),
            CSVRow(cells: ["C", "D"]),
            CSVRow(cells: ["E", "F"])
        ]
        document.rowCount = 3
        document.columnCount = 2
        document.hasUnsavedChanges = false
        
        document.deleteRow(at: 1)
        
        XCTAssertEqual(document.rowCount, 2)
        XCTAssertEqual(document.rows.count, 2)
        XCTAssertEqual(document.rows[0].cells, ["A", "B"])
        XCTAssertEqual(document.rows[1].cells, ["E", "F"])
        XCTAssertTrue(document.hasUnsavedChanges)
    }
    
    func testAddColumn() {
        document.headers = ["Test1"]
        document.rows = [
            CSVRow(cells: ["A"]),
            CSVRow(cells: ["B"])
        ]
        document.rowCount = 2
        document.columnCount = 1
        document.hasUnsavedChanges = false
        
        document.addColumn(name: "Test2")
        
        XCTAssertEqual(document.columnCount, 2)
        XCTAssertEqual(document.headers, ["Test1", "Test2"])
        XCTAssertEqual(document.rows[0].cells, ["A", ""])
        XCTAssertEqual(document.rows[1].cells, ["B", ""])
        XCTAssertTrue(document.hasUnsavedChanges)
    }
    
    func testDeleteColumn() {
        document.headers = ["Test1", "Test2", "Test3"]
        document.rows = [
            CSVRow(cells: ["A", "B", "C"]),
            CSVRow(cells: ["D", "E", "F"])
        ]
        document.rowCount = 2
        document.columnCount = 3
        document.hasUnsavedChanges = false
        
        document.deleteColumn(at: 1)
        
        XCTAssertEqual(document.columnCount, 2)
        XCTAssertEqual(document.headers, ["Test1", "Test3"])
        XCTAssertEqual(document.rows[0].cells, ["A", "C"])
        XCTAssertEqual(document.rows[1].cells, ["D", "F"])
        XCTAssertTrue(document.hasUnsavedChanges)
    }
    
    func testUpdateCell() {
        document.headers = ["Test1", "Test2"]
        document.rows = [
            CSVRow(cells: ["A", "B"]),
            CSVRow(cells: ["C", "D"])
        ]
        document.rowCount = 2
        document.columnCount = 2
        document.hasUnsavedChanges = false
        
        document.updateCell(row: 1, column: 0, value: "Updated")
        
        XCTAssertEqual(document.rows[1].cells[0], "Updated")
        XCTAssertTrue(document.hasUnsavedChanges)
    }
    
    func testLoadEmptyFile() {
        let emptyFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("empty.csv")
        try? "".write(to: emptyFileURL, atomically: true, encoding: .utf8)
        
        XCTAssertThrowsError(try document.loadCSV(from: emptyFileURL)) { error in
            XCTAssertEqual(error as? CSVError, CSVError.emptyFile)
        }
        
        try? FileManager.default.removeItem(at: emptyFileURL)
    }
    
    func testSaveAndReload() throws {
        // Initial data
        document.headers = ["Test1", "Test2"]
        document.rows = [
            CSVRow(cells: ["A", "B"]),
            CSVRow(cells: ["C", "D"])
        ]
        document.rowCount = 2
        document.columnCount = 2
        
        // Save
        let saveURL = FileManager.default.temporaryDirectory.appendingPathComponent("save_reload_test.csv")
        try document.saveCSV(to: saveURL)
        
        // Create new document and load
        let newDocument = CSVDocument()
        try newDocument.loadCSV(from: saveURL)
        
        // Verify
        XCTAssertEqual(newDocument.headers, document.headers)
        XCTAssertEqual(newDocument.rows.count, document.rows.count)
        for i in 0..<document.rows.count {
            XCTAssertEqual(newDocument.rows[i].cells, document.rows[i].cells)
        }
        XCTAssertEqual(newDocument.rowCount, document.rowCount)
        XCTAssertEqual(newDocument.columnCount, document.columnCount)
        
        try FileManager.default.removeItem(at: saveURL)
    }
    
    func testSaveWithCurrentURL() throws {
        // Setup initial state
        document.headers = ["Test1", "Test2"]
        document.rows = [
            CSVRow(cells: ["A", "B"]),
            CSVRow(cells: ["C", "D"])
        ]
        document.rowCount = 2
        document.columnCount = 2
        document.hasUnsavedChanges = true
        
        // Set current URL
        let saveURL = FileManager.default.temporaryDirectory.appendingPathComponent("current_save_test.csv")
        document.currentURL = saveURL
        
        // Test save
        try document.save()
        
        // Verify file was saved
        let savedContent = try String(contentsOf: saveURL, encoding: .utf8)
        XCTAssertEqual(savedContent, "Test1,Test2\nA,B\nC,D")
        XCTAssertFalse(document.hasUnsavedChanges)
        
        // Clean up
        try FileManager.default.removeItem(at: saveURL)
    }
    
    func testSaveWithNoCurrentURL() {
        document.hasUnsavedChanges = true
        document.currentURL = nil
        
        XCTAssertThrowsError(try document.save()) { error in
            XCTAssertEqual(error as? CSVError, CSVError.noActiveDocument)
        }
    }
    
    func testUpdateHeader() {
        // Setup
        document.headers = ["Test1", "Test2", "Test3"]
        document.rows = [
            CSVRow(cells: ["A", "B", "C"]),
            CSVRow(cells: ["D", "E", "F"])
        ]
        document.rowCount = 2
        document.columnCount = 3
        document.hasUnsavedChanges = false
        
        // Update header
        document.headers[1] = "Updated Header"
        
        // Verify
        XCTAssertEqual(document.headers, ["Test1", "Updated Header", "Test3"])
        XCTAssertEqual(document.columnCount, 3)
        XCTAssertEqual(document.rows[0].cells, ["A", "B", "C"])
        XCTAssertEqual(document.rows[1].cells, ["D", "E", "F"])
    }
}
