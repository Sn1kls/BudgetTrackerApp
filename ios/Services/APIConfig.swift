import Foundation

struct APIConfig {

    // Simulator default; set API_BASE_URL in the Xcode scheme for a device or tunnel.
    static let baseURL: URL = {
        let raw = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://localhost:8000/api"
        return URL(string: raw)!
    }()
}
