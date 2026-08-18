import Foundation
import HTTPTypes
import OpenAPIRuntime

/// A `ClientTransport` test double that records the outgoing request and
/// returns a canned response, so tests can verify repository behavior without
/// performing real network calls.
final class MockClientTransport: ClientTransport, @unchecked Sendable {
    private(set) var capturedRequests: [HTTPRequest] = []

    private let responseBodyProvider: () -> String

    init(responseBody: String) {
        self.responseBodyProvider = { responseBody }
    }

    init(responseBodyProvider: @escaping () -> String) {
        self.responseBodyProvider = responseBodyProvider
    }

    func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        capturedRequests.append(request)
        var response = HTTPResponse(status: .ok)
        response.headerFields[.contentType] = "application/json"
        return (response, HTTPBody(responseBodyProvider()))
    }
}
