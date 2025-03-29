import XCTest
@testable import simple_csv

final class ContentViewTests: XCTestCase {
    var document: CSVDocument!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        document = CSVDocument()
        document.headers = ["Test1", "Test2"]
        document.rows = [["A", "B"], ["C", "D"]]
        document.rowCount = 2
        document.columnCount = 2
    }
    
    override func tearDownWithError() throws {
        document = nil
        try super.tearDownWithError()
    }
    
    func testDeleteRow() {
        // Initial state
        XCTAssertEqual(document.rows.count, 2)
        XCTAssertEqual(document.rows[0], ["A", "B"])
        XCTAssertEqual(document.rows[1], ["C", "D"])
        
        // Delete first row
        document.deleteRow(at: 0)
        
        // Verify state after deletion
        XCTAssertEqual(document.rows.count, 1)
        XCTAssertEqual(document.rows[0], ["C", "D"])
        XCTAssertEqual(document.rowCount, 1)
        XCTAssertTrue(document.hasUnsavedChanges)
    }
    
    func testDeleteRowOutOfBounds() {
        // Initial state
        XCTAssertEqual(document.rows.count, 2)
        
        // Try to delete row at invalid index
        document.deleteRow(at: 5)
        
        // Verify state remains unchanged
        XCTAssertEqual(document.rows.count, 2)
        XCTAssertEqual(document.rowCount, 2)
    }
    
    func testAddRow() {
        // Initial state
        XCTAssertEqual(document.rows.count, 2)
        
        // Add new row
        document.addRow()
        
        // Verify new row is added with empty cells
        XCTAssertEqual(document.rows.count, 3)
        XCTAssertEqual(document.rows[2], ["", ""])
        XCTAssertEqual(document.rowCount, 3)
        XCTAssertTrue(document.hasUnsavedChanges)
    }
    
    func testUpdateCell() {
        // Initial state
        XCTAssertEqual(document.rows[0][0], "A")
        
        // Update cell
        document.updateCell(row: 0, column: 0, value: "Updated")
        
        // Verify cell is updated
        XCTAssertEqual(document.rows[0][0], "Updated")
        XCTAssertTrue(document.hasUnsavedChanges)
    }
    
    func testUpdateCellOutOfBounds() {
        // Initial state
        let initialRows = document.rows
        
        // Try to update cell at invalid indices
        document.updateCell(row: 5, column: 5, value: "Invalid")
        
        // Verify state remains unchanged
        XCTAssertEqual(document.rows, initialRows)
    }
}
