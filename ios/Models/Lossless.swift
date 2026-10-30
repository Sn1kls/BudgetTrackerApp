// MARK: - Lossless String/Double
@propertyWrapper
struct LosslessDouble: Codable {
    var wrappedValue: Double

    init(wrappedValue: Double) { self.wrappedValue = wrappedValue }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let number = try? container.decode(Double.self)               { wrappedValue = number; return }
        if let text = try? container.decode(String.self), let number = Double(text) {
            wrappedValue = number; return
        }
        throw DecodingError.typeMismatch(
            Double.self,
            .init(codingPath: decoder.codingPath,
                  debugDescription: "Need number or numeric string")
        )
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}
