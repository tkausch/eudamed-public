![EudamedPublicSwift](Eudamed.png)

A Swift package providing a type-safe client and offline-capable data layer for the [EUDAMED](https://ec.europa.eu/tools/eudamed/) public API.

EUDAMED is the IT system established by Regulation (EU) 2017/745 on medical devices and Regulation (EU) 2017/746 on in vitro diagnostic medical devices.

## Requirements

- Swift 5.9+
- macOS 14 / iOS 17 or later
- SwiftData — required for `EudamedClient` only

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/tkausch/eudamed-public", from: "0.1.1")
]
```

Add the products you need:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "EudamedClient", package: "eudamed-public"),  // domain models + repositories
        .product(name: "EudamedCore",   package: "eudamed-public"),  // raw REST client only
    ]
)
```

## Products

| Product | Description |
|---|---|
| `EudamedCore` | Low-level OpenAPI-generated REST client. Use when you only need raw API access without SwiftData. |
| `EudamedClient` | Domain models (`Actor`, `UdiDevice`, `ReferenceEntry`) and the three-layer repository pattern. Depends on SwiftData. |
| `EudamedServer` | Server-side library for building Vapor-based EUDAMED back-ends. |

---

## EudamedCore

```swift
import EudamedCore

let client = try Client()
let response = try await client.getActors(.init(query: .init(NAME: "Acme")))
let actors = try response.ok.body.json.value ?? []
```

The raw client returns one page at a time. For automatic pagination use the `Remote*Repository` types in `EudamedClient` (see below).

### Available operations

| Operation | Path | Description |
|---|---|---|
| `getActors` | `/actors` | Search economic operators (manufacturers, authorised representatives, importers, etc.) |
| `getReference` | `/reference` | Look up reference / nomenclature data |
| `getUdi` | `/udi` | Search Unique Device Identification (UDI) records |

---

## EudamedClient

`EudamedClient` provides SwiftData-backed domain models and a three-layer repository pattern.

### Domain models

`Actor`, `UdiDevice`, and `ReferenceEntry` are SwiftData `@Model` classes with unique constraints on their primary keys.

### Repository pattern

Each entity has three repository implementations:

| Class | Description |
|---|---|
| `RemoteActorRepository` | Fetches from the live EUDAMED API, follows pagination automatically. |
| `LocalActorRepository` | Reads and writes a SwiftData store (`@ModelActor`-isolated). |
| `CachingActorRepository` | Offline-first: `search` always hits the local store; `sync()` fetches from remote and upserts locally. |

The same pattern applies to `UdiDevice` (`RemoteUdiDevicesRepository`, `LocalUdiDevicesRepository`, `CachingUdiDeviceRepository`) and `ReferenceEntry` (`RemoteReferenceRepository`, `LocalReferenceRepository`, `CachingReferenceRepository`).

### Offline-first usage

```swift
import EudamedClient
import SwiftData

let container = try ModelContainer(
    for: Actor.self, UdiDevice.self, ReferenceEntry.self
)

let repo = try CachingUdiDeviceRepository(modelContainer: container)

// Pull fresh data from EUDAMED and persist it locally
try await repo.sync()

// All subsequent reads come from the local SwiftData store (no network)
let devices = try await repo.search(query: UdiDevicesQuery(tradeName: "Acme"))
```

### Query types

Each repository accepts a query struct with optional filter fields:

```swift
UdiDevicesQuery(primaryDi: "...", mfSrn: "...", nomenclatureCode: "...", ...)
ActorQuery(name: "...", actorType: "...", countryIso2Code: "...", ...)
ReferenceQuery(code: "...", language: "en", ...)
```

All fields are optional; omitting a field means "no filter on that field".

---

## Project layout

| Path | Purpose |
|---|---|
| `Sources/EudamedRest/openapi.yaml` | OpenAPI specification (source of truth) |
| `Sources/EudamedRest/openapi-generator-config.yaml` | Generator configuration |
| `Sources/EudamedRest/GeneratedSources/` | Generated `Types.swift` and `Client.swift`, checked into source control |
| `Sources/EudamedRest/EudamedClient.swift` | Convenience `Client()` initialiser (points at the EUDAMED server) |
| `Sources/EudamedRest/TypesExtensions.swift` | Convenience extensions on generated OpenAPI types |
| `Sources/EudamedClient/models/` | SwiftData `@Model` domain types (`Actor`, `UdiDevice`, `ReferenceEntry`) |
| `Sources/EudamedClient/Remote*.swift` | Remote repository implementations (live API + pagination) |
| `Sources/EudamedClient/Local*.swift` | Local repository implementations (SwiftData `@ModelActor`) |
| `Sources/EudamedClient/Caching*.swift` | Caching repository implementations (offline-first composition) |
| `Sources/EudamedServer/` | Server-side library skeleton |
| `Tests/EudamedRestTests/` | Unit tests for the REST client using a mock transport |
| `Tests/EudamedClientTests/` | Unit tests for local, remote, and caching repositories (in-memory SwiftData) |

## Regenerating sources

After changing `openapi.yaml` or `openapi-generator-config.yaml`, regenerate the Swift sources with:

```sh
swift package plugin --allow-writing-to-package-directory generate-code-from-openapi
```

Then build and test to confirm:

```sh
swift build
swift test
```

Commit the updated `openapi.yaml` and `GeneratedSources/` together.

## License

EudamedPublicSwift is available for **noncommercial use** under the
[PolyForm Noncommercial License 1.0.0](LICENSE). See [EULA.md](EULA.md)
for the full End User License Agreement, including restrictions on
commercial use.

For commercial licensing, contact thomas@kausch.li.
