import Foundation

struct Transaction: Identifiable {
    let id: Int64
    let userId: Int64
    let type: String
    let amount: Double
    let category: String
    let description: String
    let date: Date
}
