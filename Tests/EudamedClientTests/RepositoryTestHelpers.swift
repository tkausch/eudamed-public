import XCTest
import SwiftData
@testable import EudamedRest
@testable import EudamedClient

func makeClient(_ body: String) throws -> Client {
    Client(serverURL: try Servers.Server1.url(), transport: MockRestTransport(responseBody: body))
}

func makePaginatingClient(firstPage: String, secondPage: String) throws -> Client {
    var callCount = 0
    return Client(
        serverURL: try Servers.Server1.url(),
        transport: MockRestTransport {
            defer { callCount += 1 }
            return callCount == 0 ? firstPage : secondPage
        }
    )
}
