// Generated client types and operations are produced at build time by the
// swift-openapi-generator plugin from openapi.yaml.

import Foundation
import HTTPTypes
import OpenAPIRuntime
import OpenAPIURLSession

extension Client {
    /// Creates a client for the EUDAMED public API, authenticated with an
    /// Ocp-Apim-Subscription-Key header.
    public init(subscriptionKey: String) throws {
        self.init(
            serverURL: try Servers.Server1.url(),
            transport: URLSessionTransport(),
            middlewares: [SubscriptionKeyMiddleware(subscriptionKey: subscriptionKey)]
        )
    }
}

private struct SubscriptionKeyMiddleware: ClientMiddleware {
    let subscriptionKey: String

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        request.headerFields[HTTPField.Name("Ocp-Apim-Subscription-Key")!] = subscriptionKey
        return try await next(request, body, baseURL)
    }
}
