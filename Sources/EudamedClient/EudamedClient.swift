// Generated client types and operations are produced at build time by the
// swift-openapi-generator plugin from openapi.yaml.

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

extension Client {
    /// Creates a client for the EUDAMED public API.
    public init() throws {
        self.init(
            serverURL: try Servers.Server1.url(),
            transport: URLSessionTransport()
        )
    }
}
