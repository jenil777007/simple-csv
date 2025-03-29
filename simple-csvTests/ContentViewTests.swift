import XCTest
@testable import simple_csv

final class ContentViewTests: XCTestCase {
    var document: CSVDocument!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        document = CSVDocument()
        document.headers = ["Test1", "Test2"]
        document.rows = [
            CSVRow(cells: ["A", "B"]),
            CSVRow(cells: ["C", "D"])
        ]
        document.rowCount = 2
        document.columnCount = 2
    }
    
    override func tearDownWithError() throws {
        document = nil
        try super.tearDownWithError()
    }
    
    func testAddRow() {
        let initialCount = document.rows.count
        document.addRow()
        
        XCTAssertEqual(document.rows.count, initialCount + 1)
        XCTAssertEqual(document.rows.last?.cells.count, document.columnCount)
        XCTAssertEqual(document.rowCount, initialCount + 1)
        
        // Verify the new row has empty cells
        if let lastRow = document.rows.last {
            XCTAssertEqual(lastRow.cells, Array(repeating: "", count: document.columnCount))
        }
    }
    
    func testDeleteRow() {
        let initialCount = document.rows.count
        let firstRowCells = document.rows[0].cells
        
        document.deleteRow(at: 1) // Delete second row
        
        XCTAssertEqual(document.rows.count, initialCount - 1)
        XCTAssertEqual(document.rowCount, initialCount - 1)
        XCTAssertEqual(document.rows[0].cells, firstRowCells) // First row should remain unchanged
    }
    
    func testDeleteRowOutOfBounds() {
        let initialCount = document.rows.count
        
        // Try to delete a row at an invalid index
        document.deleteRow(at: document.rows.count + 1)
        
        // Nothing should change
        XCTAssertEqual(document.rows.count, initialCount)
        XCTAssertEqual(document.rowCount, initialCount)
    }
    
    func testUpdateCell() {
        let newValue = "Updated"
        document.updateCell(row: 0, column: 0, value: newValue)
        
        XCTAssertEqual(document.rows[0].cells[0], newValue)
    }
    
    func testUpdateCellOutOfBounds() {
        let originalValue = document.rows[0].cells[0]
        
        // Try to update a cell at invalid indices
        document.updateCell(row: document.rows.count + 1, column: 0, value: "New")
        
        // Original value should remain unchanged
        XCTAssertEqual(document.rows[0].cells[0], originalValue)
    }
}
