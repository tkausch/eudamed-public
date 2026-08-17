import Foundation
import HTTPTypes
import OpenAPIRuntime

/// A `ClientTransport` test double that records the outgoing request and
/// returns a canned response, so tests can verify `Client` behavior without
/// performing real network calls.
final class MockClientTransport: ClientTransport, @unchecked Sendable {
    private(set) var capturedRequest: HTTPRequest?
    private(set) var capturedBaseURL: URL?
    private(set) var capturedOperationID: String?

    private let responseStatus: HTTPResponse.Status
    private let responseBody: String

    init(responseStatus: HTTPResponse.Status = .ok, responseBody: String) {
        self.responseStatus = responseStatus
        self.responseBody = responseBody
    }

    func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        capturedRequest = request
        capturedBaseURL = baseURL
        capturedOperationID = operationID

        var response = HTTPResponse(status: responseStatus)
        response.headerFields[.contentType] = "application/json"
        return (response, HTTPBody(responseBody))
    }
}
