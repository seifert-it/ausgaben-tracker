import Charts
import SwiftUI

private enum AppSection: String, CaseIterable, Identifiable {
  case overview = "Übersicht"
  case expenses = "Ausgaben"
  case archive = "Archiv"
  var id: String { rawValue }
  var icon: String {
    switch self {
    case .overview: "chart.bar.xaxis"
    case .expenses: "list.bullet.rectangle"
    case .archive: "archivebox.fill"
    }
  }
}

struct ContentView: View {
  @ObservedObject var store: ExpenseStore
  @State private var selection: AppSection? = .overview
  @State private var showAddExpense = false
  @State private var showSettings = false

  var body: some View {
    NavigationSplitView {
      VStack(spacing: 0) {
        BrandLogo().frame(height: 104).padding(.horizontal, 22).padding(.vertical, 10)
        HStack {
          Circle().fill(RetroTheme.mint).frame(width: 8, height: 8)
          Text("LOKAL · SYSTEM BEREIT").font(.system(size: 10, weight: .bold, design: .monospaced))
          Spacer()
        }
        .foregroundStyle(RetroTheme.ink).padding(.horizontal, 16).padding(.bottom, 8)

        List(AppSection.allCases, selection: $selection) { section in
          Label(section.rawValue, systemImage: section.icon).tag(section)
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)

        VStack(alignment: .leading, spacing: 6) {
          Text("AKTUELLER ZEITRAUM").font(.system(size: 10, weight: .black, design: .monospaced))
          Text(
            store.currentPeriod.start.formatted(.dateTime.day().month(.abbreviated)) + " – "
              + store.currentPeriod.end.addingTimeInterval(-1).formatted(
                .dateTime.day().month(.abbreviated).year())
          )
          .font(.system(.caption, design: .monospaced))
        }
        .foregroundStyle(RetroTheme.ink).padding(16).frame(maxWidth: .infinity, alignment: .leading)
      }
      .background(RetroTheme.paperDark)
      .navigationSplitViewColumnWidth(min: 210, ideal: 235, max: 280)
    } detail: {
      Group {
        switch selection ?? .overview {
        case .overview: DashboardView(store: store, showAddExpense: $showAddExpense)
        case .expenses: ExpenseListView(store: store, showAddExpense: $showAddExpense)
        case .archive: ArchiveView(store: store)
        }
      }
      .background(RetroTheme.paper)
    }
    .fontDesign(.monospaced)
    .tint(RetroTheme.teal)
    .toolbar {
      ToolbarItemGroup {
        Button {
          showAddExpense = true
        } label: {
          Label("Ausgabe erfassen", systemImage: "plus")
        }
        .keyboardShortcut("n")
        Button {
          showSettings = true
        } label: {
          Label("Budgets", systemImage: "slider.horizontal.3")
        }
      }
    }
    .sheet(isPresented: $showAddExpense) { AddExpenseView(store: store) }
    .sheet(isPresented: $showSettings) { SettingsView(store: store).frame(width: 480) }
    .alert(
      "Hinweis",
      isPresented: Binding(
        get: { store.lastError != nil }, set: { if !$0 { store.lastError = nil } })
    ) {
      Button("OK") { store.lastError = nil }
    } message: {
      Text(store.lastError ?? "")
    }
  }
}

private struct DashboardView: View {
  @ObservedObject var store: ExpenseStore
  @Binding var showAddExpense: Bool

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        HStack(alignment: .firstTextBaseline) {
          VStack(alignment: .leading, spacing: 4) {
            Text("// AUSGABEN-LAGEBILD").font(.system(.caption, design: .monospaced).weight(.black))
              .foregroundStyle(RetroTheme.teal)
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).year())).font(
              .system(size: 28, weight: .black, design: .monospaced)
            ).foregroundStyle(RetroTheme.ink)
          }
          Spacer()
          Button {
            showAddExpense = true
          } label: {
            Label("AUSGABE ERFASSEN", systemImage: "plus")
          }.buttonStyle(.borderedProminent).controlSize(.large)
        }

        HStack(spacing: 14) {
          BudgetCard(
            title: "MONATSBUDGET", spent: store.currentTotal, limit: store.data.monthlyBudget,
            exceeded: store.monthlyExceeded,
            subtitle: store.remainingBudget >= 0
              ? "Noch \(currency(store.remainingBudget)) verfügbar"
              : "Um \(currency(-store.remainingBudget)) überschritten")
          BudgetCard(
            title: "TAGESBUDGET", spent: store.todayTotal, limit: store.data.dailyBudget,
            exceeded: store.dailyExceeded,
            subtitle: "Empfohlen ab heute: \(currency(store.recommendedDaily)) / Tag")
        }

        HStack(spacing: 14) {
          GroupBox("TAGESVERLAUF") {
            Chart(store.dailyTotals) { item in
              BarMark(
                x: .value("Tag", item.date, unit: .day),
                y: .value("Ausgaben", item.amount.doubleValue)
              )
              .foregroundStyle(
                item.amount > store.data.dailyBudget ? RetroTheme.red : RetroTheme.teal)
              RuleMark(y: .value("Tagesbudget", store.data.dailyBudget.doubleValue))
                .foregroundStyle(RetroTheme.blue).lineStyle(
                  StrokeStyle(lineWidth: 2, dash: [5, 4]))
            }
            .chartYAxis {
              AxisMarks(position: .leading) {
                AxisGridLine()
                AxisValueLabel(
                  format: Decimal.FormatStyle.Currency(code: "EUR").precision(.fractionLength(0)))
              }
            }
            .chartXAxis {
              AxisMarks(values: .stride(by: .day, count: 5)) {
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month())
              }
            }
            .frame(height: 240).padding(8)
          }
          .frame(maxWidth: .infinity)

          GroupBox("KATEGORIEN") {
            if store.categoryTotals.isEmpty {
              ContentUnavailableView(
                "Noch keine Ausgaben", systemImage: "chart.pie",
                description: Text("Erfasste Ausgaben werden hier gruppiert.")
              )
              .frame(height: 240)
            } else {
              VStack(spacing: 10) {
                Chart(store.categoryTotals) { item in
                  SectorMark(
                    angle: .value("Betrag", item.amount.doubleValue), innerRadius: .ratio(0.58),
                    angularInset: 2
                  )
                  .foregroundStyle(by: .value("Kategorie", item.category.rawValue))
                }.frame(height: 150)
                ForEach(store.categoryTotals.prefix(4)) { item in
                  HStack {
                    Label(item.category.rawValue, systemImage: item.category.symbol)
                    Spacer()
                    Text(currency(item.amount)).fontWeight(.bold)
                  }
                  .font(.caption)
                }
              }.padding(8)
            }
          }
          .frame(width: 320)
        }

        GroupBox("LETZTE AUSGABEN") {
          if store.currentExpenses.isEmpty {
            ContentUnavailableView(
              "Noch keine Ausgaben", systemImage: "tray",
              description: Text("Mit „Ausgabe erfassen“ legst du den ersten Eintrag an.")
            )
            .frame(height: 150)
          } else {
            VStack(spacing: 0) {
              ForEach(store.currentExpenses.prefix(5)) { expense in
                ExpenseRow(expense: expense, onDelete: { store.delete(expense) })
                if expense.id != store.currentExpenses.prefix(5).last?.id { Divider() }
              }
            }.padding(.horizontal, 8)
          }
        }
      }.padding(22)
    }
  }
}

private struct BudgetCard: View {
  let title: String
  let spent: Decimal
  let limit: Decimal
  let exceeded: Bool
  let subtitle: String
  private var progress: Double {
    limit > 0 ? min(spent.doubleValue / limit.doubleValue, 1) : (spent > 0 ? 1 : 0)
  }
  private var color: Color { exceeded ? RetroTheme.red : RetroTheme.blue }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(title)
        Spacer()
        Image(systemName: exceeded ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
      }
      .font(.system(.caption, design: .monospaced).weight(.black)).foregroundStyle(color)
      Text(currency(spent)).font(.system(size: 34, weight: .black, design: .monospaced))
        .foregroundStyle(color)
      Text("von \(currency(limit))").font(.system(.body, design: .monospaced)).foregroundStyle(
        .secondary)
      ProgressView(value: progress).tint(color).scaleEffect(y: 2)
      Text(subtitle).font(.system(.caption, design: .monospaced).weight(.semibold)).foregroundStyle(
        color)
    }
    .padding(16).frame(maxWidth: .infinity, alignment: .leading).pixelBorder(active: true)
  }
}

private struct ExpenseListView: View {
  @ObservedObject var store: ExpenseStore
  @Binding var showAddExpense: Bool
  @State private var query = ""
  @State private var category: ExpenseCategory?

  private var visible: [Expense] {
    store.currentExpenses.filter { expense in
      (query.isEmpty || expense.title.localizedCaseInsensitiveContains(query)
        || expense.note.localizedCaseInsensitiveContains(query))
        && (category == nil || expense.category == category)
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        VStack(alignment: .leading, spacing: 3) {
          Text("AUSGABEN").font(.system(size: 26, weight: .black, design: .monospaced))
            .foregroundStyle(RetroTheme.ink)
          Text("\(visible.count) Einträge · \(currency(visible.reduce(0) { $0 + $1.amount }))")
            .foregroundStyle(.secondary)
        }
        Spacer()
        Picker("Kategorie", selection: $category) {
          Text("Alle Kategorien").tag(nil as ExpenseCategory?)
          ForEach(ExpenseCategory.allCases) { Text($0.rawValue).tag(Optional($0)) }
        }.frame(width: 190)
        Button {
          showAddExpense = true
        } label: {
          Label("ERFASSEN", systemImage: "plus")
        }.buttonStyle(.borderedProminent)
      }.padding(20)

      if visible.isEmpty {
        ContentUnavailableView(
          query.isEmpty ? "Keine Ausgaben" : "Kein Treffer",
          systemImage: query.isEmpty ? "tray" : "magnifyingglass"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        List(visible) { expense in
          ExpenseRow(expense: expense, onDelete: { store.delete(expense) })
            .listRowBackground(Color.clear)
        }.listStyle(.plain).scrollContentBackground(.hidden)
      }
    }.searchable(text: $query, prompt: "Titel oder Notiz")
  }
}

private struct ExpenseRow: View {
  let expense: Expense
  let onDelete: () -> Void
  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: expense.category.symbol).frame(width: 30, height: 30).foregroundStyle(
        RetroTheme.teal)
      VStack(alignment: .leading, spacing: 3) {
        Text(expense.title).fontWeight(.bold).foregroundStyle(RetroTheme.ink)
        HStack {
          Text(expense.category.rawValue.uppercased())
          Text("·")
          Text(expense.date.formatted(date: .abbreviated, time: .omitted))
        }
        .font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
        if !expense.note.isEmpty {
          Text(expense.note).font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
      }
      Spacer()
      Text(currency(expense.amount)).font(.system(.body, design: .monospaced).weight(.black))
        .foregroundStyle(RetroTheme.ink)
      Button(role: .destructive, action: onDelete) { Image(systemName: "trash") }.buttonStyle(
        .borderless
      ).help("Ausgabe löschen")
    }.padding(.vertical, 8)
  }
}

private struct ArchiveView: View {
  @ObservedObject var store: ExpenseStore
  @State private var selected: BudgetArchive?

  var body: some View {
    HSplitView {
      VStack(alignment: .leading, spacing: 0) {
        Text("MONATSARCHIV").font(.system(size: 22, weight: .black, design: .monospaced))
          .foregroundStyle(RetroTheme.ink).padding(18)
        if store.data.archives.isEmpty {
          ContentUnavailableView(
            "Archiv noch leer", systemImage: "archivebox",
            description: Text(
              "Nach dem ersten Stichtag erscheint der abgeschlossene Zeitraum automatisch hier."))
        } else {
          List(store.data.archives, selection: $selected) { archive in
            VStack(alignment: .leading, spacing: 6) {
              Text(archive.start.formatted(.dateTime.month(.wide).year())).fontWeight(.black)
              HStack {
                Text(currency(archive.total))
                Spacer()
                Text("\(archive.expenseCount) Einträge")
              }.font(.caption).foregroundStyle(.secondary)
            }.padding(.vertical, 8).tag(archive)
          }.listStyle(.sidebar).scrollContentBackground(.hidden)
        }
      }.frame(minWidth: 270, idealWidth: 310)

      if let selected {
        ScrollView {
          VStack(alignment: .leading, spacing: 16) {
            Text(selected.start.formatted(.dateTime.month(.wide).year())).font(
              .system(size: 28, weight: .black, design: .monospaced)
            ).foregroundStyle(RetroTheme.ink)
            BudgetCard(
              title: "ABGESCHLOSSENER ZEITRAUM", spent: selected.total,
              limit: selected.monthlyBudget, exceeded: selected.total > selected.monthlyBudget,
              subtitle: selected.total > selected.monthlyBudget
                ? "Budget überschritten" : "Budget eingehalten")
            GroupBox("AUSGABEN · \(selected.expenseCount)") {
              VStack(spacing: 0) {
                ForEach(store.expenses(for: selected)) { expense in
                  ExpenseRow(expense: expense, onDelete: { store.delete(expense) })
                  Divider()
                }
              }.padding(.horizontal, 8)
            }
          }.padding(22)
        }
      } else {
        ContentUnavailableView("Zeitraum auswählen", systemImage: "calendar")
      }
    }
  }
}

struct AddExpenseView: View {
  @ObservedObject var store: ExpenseStore
  @Environment(\.dismiss) private var dismiss
  @State private var title = ""
  @State private var amount: Decimal?
  @State private var date = Date()
  @State private var category: ExpenseCategory = .food
  @State private var note = ""

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("AUSGABE ERFASSEN").font(.system(size: 24, weight: .black, design: .monospaced))
        .foregroundStyle(RetroTheme.ink)
      Form {
        TextField("Bezeichnung", text: $title, prompt: Text("z. B. Supermarkt"))
        TextField("Betrag", value: $amount, format: .currency(code: "EUR")).multilineTextAlignment(
          .trailing)
        DatePicker("Datum", selection: $date, displayedComponents: .date)
        Picker("Kategorie", selection: $category) {
          ForEach(ExpenseCategory.allCases) { Label($0.rawValue, systemImage: $0.symbol).tag($0) }
        }
        TextField("Notiz (optional)", text: $note)
      }.formStyle(.grouped)
      HStack {
        Spacer()
        Button("Abbrechen") { dismiss() }.keyboardShortcut(.cancelAction)
        Button("SPEICHERN") {
          guard let amount, amount > 0 else { return }
          store.add(
            title: title.isEmpty ? category.rawValue : title, amount: amount, date: date,
            category: category, note: note)
          dismiss()
        }.buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction).disabled(
          amount == nil || amount! <= 0)
      }
    }.padding(24).frame(width: 500)
  }
}

struct SettingsView: View {
  @ObservedObject var store: ExpenseStore
  @Environment(\.dismiss) private var dismiss
  @State private var monthlyText = ""
  @State private var dailyText = ""
  @State private var resetDay = 1

  private var monthlyValue: Decimal? { parseMoney(monthlyText) }
  private var dailyValue: Decimal? { parseMoney(dailyText) }
  private var isValid: Bool {
    guard let monthlyValue, let dailyValue else { return false }
    return monthlyValue >= 0 && dailyValue >= 0
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("BUDGETS & STICHTAG").font(.system(size: 22, weight: .black, design: .monospaced))
        .foregroundStyle(RetroTheme.ink)
      VStack(alignment: .leading, spacing: 16) {
        LimitField(
          title: "MONATSLIMIT", help: "Maximale Ausgaben pro Budgetzeitraum", text: $monthlyText)
        LimitField(title: "TAGESLIMIT", help: "Maximale Ausgaben pro Kalendertag", text: $dailyText)
        Divider()
        HStack {
          VStack(alignment: .leading, spacing: 3) {
            Text("MONATLICHER STICHTAG").font(.system(.caption, design: .monospaced).weight(.black))
              .foregroundStyle(RetroTheme.ink)
            Text("An diesem Tag beginnt ein neuer Budgetzeitraum.").font(.caption).foregroundStyle(
              .secondary)
          }
          Spacer()
          Stepper("\(resetDay).", value: $resetDay, in: 1...28).fixedSize()
        }
        if !isValid {
          Label(
            "Bitte gültige Beträge eingeben, zum Beispiel 1200 oder 40,50.",
            systemImage: "exclamationmark.triangle.fill"
          )
          .font(.caption).foregroundStyle(RetroTheme.red)
        }
        Text(
          "Am Stichtag beginnt automatisch ein neuer Budgetzeitraum. Abgeschlossene Zeiträume bleiben mit allen Ausgaben lokal im Archiv."
        )
        .font(.caption).foregroundStyle(.secondary)
      }
      .padding(16).pixelBorder(active: true)
      HStack {
        Spacer()
        Button("Abbrechen") { dismiss() }
        Button("ÜBERNEHMEN") {
          guard let monthlyValue, let dailyValue else { return }
          store.updateBudgets(monthly: monthlyValue, daily: dailyValue, resetDay: resetDay)
          dismiss()
        }
        .buttonStyle(.borderedProminent)
        .keyboardShortcut(.defaultAction)
        .disabled(!isValid)
      }
    }.padding(24)
      .onAppear {
        monthlyText = editableMoney(store.data.monthlyBudget)
        dailyText = editableMoney(store.data.dailyBudget)
        resetDay = store.data.resetDay
      }
  }
}

private struct LimitField: View {
  let title: String
  let help: String
  @Binding var text: String

  var body: some View {
    HStack(alignment: .center, spacing: 18) {
      VStack(alignment: .leading, spacing: 3) {
        Text(title).font(.system(.caption, design: .monospaced).weight(.black)).foregroundStyle(
          RetroTheme.ink)
        Text(help).font(.caption).foregroundStyle(.secondary)
      }
      Spacer()
      HStack(spacing: 6) {
        TextField("0,00", text: $text)
          .multilineTextAlignment(.trailing)
          .textFieldStyle(.roundedBorder)
          .frame(width: 130)
          .accessibilityLabel(title)
        Text("€").fontWeight(.bold).foregroundStyle(RetroTheme.ink)
      }
    }
  }
}

private func currency(_ value: Decimal) -> String {
  value.formatted(.currency(code: "EUR").locale(Locale(identifier: "de_DE")))
}

private func editableMoney(_ value: Decimal) -> String {
  value.formatted(.number.locale(Locale(identifier: "de_DE")).precision(.fractionLength(0...2)))
}

private func parseMoney(_ input: String) -> Decimal? {
  var value = input.trimmingCharacters(in: .whitespacesAndNewlines)
    .replacingOccurrences(of: "€", with: "")
    .replacingOccurrences(of: " ", with: "")
    .replacingOccurrences(of: "\u{00A0}", with: "")
  if value.contains(",") {
    value = value.replacingOccurrences(of: ".", with: "")
    value = value.replacingOccurrences(of: ",", with: ".")
  }
  return Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))
}
