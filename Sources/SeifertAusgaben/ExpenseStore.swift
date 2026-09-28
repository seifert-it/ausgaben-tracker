import Foundation
import SwiftUI

@MainActor
final class ExpenseStore: ObservableObject {
  @Published private(set) var data = AppData()
  @Published var lastError: String?

  private let calendar = Calendar.autoupdatingCurrent
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder
  private let fileURL: URL

  init(fileURL: URL? = nil) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    self.encoder = encoder

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    self.decoder = decoder

    if let fileURL {
      self.fileURL = fileURL
    } else {
      let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        .first!
      self.fileURL = base.appending(path: "de.seifert-it.ausgaben/data.json")
    }

    load()
    rollPeriodIfNeeded()
  }

  var currentPeriod: Period { period(containing: Date()) }

  var currentExpenses: [Expense] {
    expenses(in: currentPeriod).sorted { $0.date > $1.date }
  }

  var currentTotal: Decimal { currentExpenses.reduce(0) { $0 + $1.amount } }

  var todayTotal: Decimal {
    data.expenses.filter { calendar.isDateInToday($0.date) }.reduce(0) { $0 + $1.amount }
  }

  var remainingBudget: Decimal { data.monthlyBudget - currentTotal }
  var monthlyExceeded: Bool { currentTotal > data.monthlyBudget }
  var dailyExceeded: Bool { todayTotal > data.dailyBudget }

  var daysRemaining: Int {
    max(
      1,
      calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: currentPeriod.end)
        .day ?? 1)
  }

  var recommendedDaily: Decimal {
    max(0, remainingBudget / Decimal(daysRemaining))
  }

  var dailyTotals: [DailyTotal] {
    let grouped = Dictionary(grouping: currentExpenses) { calendar.startOfDay(for: $0.date) }
    var cursor = currentPeriod.start
    var result: [DailyTotal] = []
    let today = calendar.startOfDay(for: Date())
    while cursor <= min(today, currentPeriod.end) {
      result.append(
        DailyTotal(date: cursor, amount: grouped[cursor, default: []].reduce(0) { $0 + $1.amount }))
      cursor = calendar.date(byAdding: .day, value: 1, to: cursor)!
    }
    return result
  }

  var categoryTotals: [CategoryTotal] {
    Dictionary(grouping: currentExpenses, by: \.category)
      .map { CategoryTotal(category: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
      .sorted { $0.amount > $1.amount }
  }

  func add(title: String, amount: Decimal, date: Date, category: ExpenseCategory, note: String) {
    data.expenses.append(
      Expense(
        title: title.trimmingCharacters(in: .whitespacesAndNewlines), amount: amount, date: date,
        category: category, note: note.trimmingCharacters(in: .whitespacesAndNewlines)))
    rollPeriodIfNeeded(forceArchiveRefresh: true)
  }

  func delete(_ expense: Expense) {
    data.expenses.removeAll { $0.id == expense.id }
    rollPeriodIfNeeded(forceArchiveRefresh: true)
  }

  func updateBudgets(monthly: Decimal, daily: Decimal, resetDay: Int) {
    data.monthlyBudget = max(0, monthly)
    data.dailyBudget = max(0, daily)
    data.resetDay = min(28, max(1, resetDay))
    rollPeriodIfNeeded(forceArchiveRefresh: true)
  }

  func expenses(for archive: BudgetArchive) -> [Expense] {
    data.expenses.filter { $0.date >= archive.start && $0.date < archive.end }.sorted {
      $0.date > $1.date
    }
  }

  func exportURL() -> URL { fileURL }

  func period(containing date: Date) -> Period {
    let day = calendar.component(.day, from: date)
    var components = calendar.dateComponents([.year, .month], from: date)
    components.day = data.resetDay
    let thisReset = calendar.startOfDay(for: calendar.date(from: components)!)
    let start =
      day >= data.resetDay ? thisReset : calendar.date(byAdding: .month, value: -1, to: thisReset)!
    let end = calendar.date(byAdding: .month, value: 1, to: start)!
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.locale = Locale(identifier: "de_DE")
    formatter.dateFormat = "yyyy-MM-dd"
    return Period(key: formatter.string(from: start), start: start, end: end)
  }

  func expenses(in period: Period) -> [Expense] {
    data.expenses.filter { $0.date >= period.start && $0.date < period.end }
  }

  private func load() {
    do {
      guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
      data = try decoder.decode(AppData.self, from: Data(contentsOf: fileURL))
    } catch {
      lastError = "Die lokalen Daten konnten nicht geladen werden: \(error.localizedDescription)"
    }
  }

  private func save() {
    do {
      try FileManager.default.createDirectory(
        at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
      try encoder.encode(data).write(to: fileURL, options: .atomic)
    } catch {
      lastError = "Die Daten konnten nicht gespeichert werden: \(error.localizedDescription)"
    }
    objectWillChange.send()
  }

  private func rollPeriodIfNeeded(forceArchiveRefresh: Bool = false) {
    let current = currentPeriod
    guard forceArchiveRefresh || data.activePeriodKey != current.key else { return }

    let priorPeriods = Set(data.expenses.map { period(containing: $0.date) })
      .filter { $0.start < current.start }
    for period in priorPeriods {
      let records = expenses(in: period)
      let snapshot = BudgetArchive(
        periodKey: period.key,
        start: period.start,
        end: period.end,
        total: records.reduce(0) { $0 + $1.amount },
        monthlyBudget: data.monthlyBudget,
        dailyBudget: data.dailyBudget,
        expenseCount: records.count
      )
      data.archives.removeAll { $0.periodKey == period.key }
      data.archives.append(snapshot)
    }
    data.archives.sort { $0.start > $1.start }
    data.activePeriodKey = current.key
    save()
  }
}
