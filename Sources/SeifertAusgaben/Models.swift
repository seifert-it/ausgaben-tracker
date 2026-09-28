import Foundation

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
  case food = "Lebensmittel"
  case mobility = "Mobilität"
  case leisure = "Freizeit"
  case household = "Haushalt"
  case health = "Gesundheit"
  case subscriptions = "Abos"
  case other = "Sonstiges"

  var id: String { rawValue }

  var symbol: String {
    switch self {
    case .food: "cart.fill"
    case .mobility: "car.fill"
    case .leisure: "ticket.fill"
    case .household: "house.fill"
    case .health: "cross.case.fill"
    case .subscriptions: "repeat.circle.fill"
    case .other: "square.grid.2x2.fill"
    }
  }
}

struct Expense: Identifiable, Codable, Hashable {
  var id = UUID()
  var title: String
  var amount: Decimal
  var date: Date
  var category: ExpenseCategory
  var note: String = ""
  var createdAt = Date()
}

struct BudgetArchive: Identifiable, Codable, Hashable {
  var id: String { periodKey }
  let periodKey: String
  let start: Date
  let end: Date
  let total: Decimal
  let monthlyBudget: Decimal
  let dailyBudget: Decimal
  let expenseCount: Int
}

struct AppData: Codable {
  var expenses: [Expense] = []
  var archives: [BudgetArchive] = []
  var monthlyBudget: Decimal = 1_200
  var dailyBudget: Decimal = 40
  var resetDay: Int = 1
  var activePeriodKey: String = ""
}

struct Period: Hashable {
  let key: String
  let start: Date
  let end: Date
}

struct DailyTotal: Identifiable {
  let date: Date
  let amount: Decimal
  var id: Date { date }
}

struct CategoryTotal: Identifiable {
  let category: ExpenseCategory
  let amount: Decimal
  var id: ExpenseCategory { category }
}
