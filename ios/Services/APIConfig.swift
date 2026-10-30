import Foundation

struct APIConfig {

    // Defaults to the local Docker backend, which the iOS Simulator can reach.
    // For a real device, set API_BASE_URL in the Xcode scheme
    // (Run > Arguments > Environment Variables), e.g. an ngrok https URL + "/api".
    static let baseURL: URL = {
        let raw = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://localhost:8000/api"
        return URL(string: raw)!
    }()
}
