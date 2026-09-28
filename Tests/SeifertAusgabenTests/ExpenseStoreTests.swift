import Foundation
import XCTest

@testable import SeifertAusgaben

@MainActor
final class ExpenseStoreTests: XCTestCase {
  func testAddingExpenseUpdatesTotals() throws {
    let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString).appending(
      path: "data.json")
    let store = ExpenseStore(fileURL: url)
    store.add(title: "Test", amount: 12.50, date: Date(), category: .other, note: "")
    XCTAssertEqual(store.currentTotal, 12.50)
    XCTAssertEqual(store.todayTotal, 12.50)
  }

  func testBudgetStateTurnsExceeded() throws {
    let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString).appending(
      path: "data.json")
    let store = ExpenseStore(fileURL: url)
    store.updateBudgets(monthly: 10, daily: 5, resetDay: 1)
    store.add(title: "Test", amount: 12, date: Date(), category: .other, note: "")
    XCTAssertTrue(store.monthlyExceeded)
    XCTAssertTrue(store.dailyExceeded)
  }
}
