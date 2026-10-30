// MARK: - Lossless String/Double
@propertyWrapper
struct LosslessDouble: Codable {
    var wrappedValue: Double

    init(wrappedValue: Double) { self.wrappedValue = wrappedValue }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let d = try? c.decode(Double.self)               { wrappedValue = d; return }
        if let s = try? c.decode(String.self), let d = Double(s) {
            wrappedValue = d; return
        }
        throw DecodingError.typeMismatch(
            Double.self,
            .init(codingPath: decoder.codingPath,
                  debugDescription: "Need number or numeric string")
        )
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(wrappedValue)
    }
}
