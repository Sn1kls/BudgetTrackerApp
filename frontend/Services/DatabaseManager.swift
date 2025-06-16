import SQLite
import SwiftUI
import Foundation

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: Connection?

    init() {
        setupDatabase()
    }

    private func setupDatabase() {
        do {
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let dbPath = path.appendingPathComponent("BudgetTracker.sqlite3").path
            print("Database path: \(dbPath)") // Вивід шляху для перевірки
            db = try Connection(dbPath)
            createTables()
        } catch {
            print("Database connection failed: \(error)")
        }
    }

    private func createTables() {
        do {
            // Створення таблиці users
            let users = Table("users")
            let id = Expression<Int64>("id")
            let email = Expression<String>("email")
            let password = Expression<String>("password")

            try db?.run(users.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(email, unique: true)
                t.column(password)
            })
            print("Table 'users' created successfully!")

            // Створення таблиці transactions
            let transactions = Table("transactions")
            let transactionId = Expression<Int64>("id")
            let userId = Expression<Int64>("user_id")
            let type = Expression<String>("type")
            let amount = Expression<Double>("amount")
            let category = Expression<String>("category")
            let description = Expression<String>("description")
            let date = Expression<Date>("date")

            try db?.run(transactions.create(ifNotExists: true) { t in
                t.column(transactionId, primaryKey: .autoincrement)
                t.column(userId)
                t.column(type)
                t.column(amount)
                t.column(category)
                t.column(description)
                t.column(date)
            })
            print("Table 'transactions' created successfully!")

            // Створення таблиці budgets
            let budgets = Table("budgets")
            let budgetId = Expression<Int64>("id")
            let budgetUserId = Expression<Int64>("user_id")
            let monthlyLimit = Expression<Double>("monthly_limit")

            try db?.run(budgets.create(ifNotExists: true) { t in
                t.column(budgetId, primaryKey: .autoincrement)
                t.column(budgetUserId)
                t.column(monthlyLimit)
            })
            print("Table 'budgets' created successfully!")

        } catch {
            print("Failed to create tables: \(error)")
        }
    }

    
    func insertUser(email: String, password: String) throws {
        let users = Table("users")
        let emailColumn = Expression<String>("email")
        let passwordColumn = Expression<String>("password")

        try db?.run(users.insert(emailColumn <- email, passwordColumn <- password))
    }
    
    func fetchAllUsers() throws -> [User] {
        let users = Table("users")
        let idColumn = Expression<Int64>("id")
        let emailColumn = Expression<String>("email")
        let passwordColumn = Expression<String>("password")

        var allUsers: [User] = []
        for user in try db!.prepare(users) {
            allUsers.append(User(
                id: user[idColumn],
                email: user[emailColumn],
                password: user[passwordColumn]
            ))
        }
        return allUsers
    }
    
    func authenticateUser(email: String, password: String) throws -> User? {
        let users = Table("users")
        let emailColumn = Expression<String>("email")
        let passwordColumn = Expression<String>("password")
        let idColumn = Expression<Int64>("id")

        // Пошук користувача за email і паролем
        if let userRow = try db?.pluck(users.filter(emailColumn == email && passwordColumn == password)) {
            return User(
                id: userRow[idColumn],
                email: userRow[emailColumn],
                password: userRow[passwordColumn]
            )
        }
        return nil
    }
    
    func fetchUserByID(userID: Int64) throws -> User? {
        let users = Table("users")
        let idColumn = Expression<Int64>("id")
        let emailColumn = Expression<String>("email")
        let passwordColumn = Expression<String>("password")

        if let userRow = try db?.pluck(users.filter(idColumn == userID)) {
            return User(
                id: userRow[idColumn],
                email: userRow[emailColumn],
                password: userRow[passwordColumn]
            )
        }
        return nil
    }

    func addTransaction(userId: Int64, type: String, amount: Double, category: String, description: String, date: Date) throws {
        let transactions = Table("transactions")
        let userIdColumn = Expression<Int64>("user_id")
        let typeColumn = Expression<String>("type")
        let amountColumn = Expression<Double>("amount")
        let categoryColumn = Expression<String>("category")
        let descriptionColumn = Expression<String>("description")
        let dateColumn = Expression<Date>("date")
        
        try db?.run(transactions.insert(
            userIdColumn <- userId,
            typeColumn <- type,
            amountColumn <- amount,
            categoryColumn <- category,
            descriptionColumn <- description,
            dateColumn <- date
        ))
    }
    
    func getAnalytics(userId: Int64) throws -> (totalIncome: Double, totalExpense: Double) {
        let transactions = Table("transactions")
        let userIdColumn = Expression<Int64>("user_id")
        let typeColumn = Expression<String>("type")
        let amountColumn = Expression<Double>("amount")

        // Обчислення загального доходу
        let totalIncome = try db?.scalar(
            transactions
                .filter(userIdColumn == userId && typeColumn == "Income")
                .select(amountColumn.sum)
        ) ?? 0.0

        // Обчислення загальних витрат
        let totalExpense = try db?.scalar(
            transactions
                .filter(userIdColumn == userId && typeColumn == "Expense")
                .select(amountColumn.sum)
        ) ?? 0.0

        return (totalIncome, totalExpense)
    }

    func setBudget(userId: Int64, limit: Double) throws {
        let budgets = Table("budgets")
        let userIdColumn = Expression<Int64>("user_id")
        let monthlyLimitColumn = Expression<Double>("monthly_limit")

        let query = budgets.filter(userIdColumn == userId)
        if try db?.pluck(query) != nil {
            try db?.run(query.update(monthlyLimitColumn <- limit))
        } else {
            try db?.run(budgets.insert(userIdColumn <- userId, monthlyLimitColumn <- limit))
        }
    }
    
    func fetchBudget(userId: Int64) throws -> Double? {
        let budgets = Table("budgets")
        let userIdColumn = Expression<Int64>("user_id")
        let monthlyLimitColumn = Expression<Double>("monthly_limit")

        let query = budgets.filter(userIdColumn == userId).select(monthlyLimitColumn)

        if let budgetRow = try db?.pluck(query) {
            return budgetRow[monthlyLimitColumn]
        }
        return nil
    }
    
    func fetchTransactions(userId: Int64, type: String) throws -> [Transaction] {
        let transactions = Table("transactions")
        let idColumn = Expression<Int64>("id")
        let userIdColumn = Expression<Int64>("user_id")
        let typeColumn = Expression<String>("type")
        let amountColumn = Expression<Double>("amount")
        let categoryColumn = Expression<String>("category")
        let descriptionColumn = Expression<String>("description")
        let dateColumn = Expression<Date>("date")

        var result: [Transaction] = []
        let query = transactions.filter(userIdColumn == userId && typeColumn == type)

        for row in try db!.prepare(query) {
            result.append(Transaction(
                id: row[idColumn],
                userId: row[userIdColumn],
                type: row[typeColumn],
                amount: row[amountColumn],
                category: row[categoryColumn],
                description: row[descriptionColumn],
                date: row[dateColumn]
            ))
        }

        return result
    }

}
