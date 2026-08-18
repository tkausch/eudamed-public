# 🇪🇺 EudamedPublicSwift 🦾🦿🫀

![EudamedPublicSwift](Eudamed.png)

A Swift package providing a type-safe client and offline-capable data layer for the [EUDAMED](https://ec.europa.eu/tools/eudamed/) public API.

EUDAMED is the IT system established by Regulation (EU) 2017/745 on medical devices and Regulation (EU) 2017/746 on in vitro diagnostic medical devices.

## Requirements

- Swift 5.9+
- SwiftData (iOS 17 / macOS 14 or later) — required for `EudamedDataModel` only

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/tkausch/eudamedPublic", branch: "main")
]
```

Add the targets you need:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "EudamedClient",    package: "eudamedPublic"),  // raw API client
        .product(name: "EudamedDataModel", package: "eudamedPublic"),  // domain models + repositories
    ]
)
```

## Targets

| Target | Description |
|---|---|
| `EudamedClient` | Low-level OpenAPI-generated client. Use directly when you want raw API access. |
| `EudamedDataModel` | Domain models (`Actor`, `UdiDevice`, `ReferenceEntry`) and the repository layer. Depends on SwiftData. |

---

## EudamedClient

```swift
import EudamedClient

let client = try Client()
let response = try await client.getActors(.init(query: .init(NAME: "Acme")))
let actors = try response.ok.body.json.value ?? []
```

The raw client returns one page at a time. For automatic pagination across all pages, use the `Remote*Repository` classes in `EudamedDataModel` (see below).

### Available operations

| Operation | Path | Description |
|---|---|---|
| `getActors` | `/actors` | Search economic operators (manufacturers, authorised representatives, importers, etc.) |
| `getReference` | `/reference` | Look up reference/nomenclature data |
| `getUdi` | `/udi` | Search Unique Device Identification (UDI) records |

---

## EudamedDataModel

`EudamedDataModel` provides SwiftData-backed domain models and a three-layer repository pattern.

### Domain models

`Actor`, `UdiDevice`, and `ReferenceEntry` are SwiftData `@Model` classes with unique constraints on their primary keys. They can be inserted directly into a `ModelContainer`.

### Repository pattern

Each entity has three repository implementations:

| Class | Description |
|---|---|
| `RemoteActorRepository` | Fetches from the live EUDAMED API, follows pagination. |
| `LocalActorRepository` | Reads/writes a SwiftData store. |
| `CachingActorRepository` | Offline-first: `search` always hits the local store; `sync()` fetches from remote and upserts locally. |

The same three-tier pattern applies to `UdiDevice` (`RemoteUdiDevicesRepository`, `LocalUdiDevicesRepository`, `CachingUdiRepository`) and `ReferenceEntry` (`RemoteReferenceRepository`, `LocalReferenceRepository`, `CachingReferenceRepository`).

### Offline-first usage

```swift
import EudamedDataModel
import SwiftData

// Create a persistent container (or use .isStoredInMemoryOnly: true for testing)
let container = try ModelContainer(
    for: Actor.self, UdiDevice.self, ReferenceEntry.self
)

let repo = try CachingUdiRepository(modelContainer: container)

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
| `Sources/EudamedClient/openapi.yaml` | OpenAPI specification (source of truth) |
| `Sources/EudamedClient/openapi-generator-config.yaml` | Generator configuration |
| `Sources/EudamedClient/GeneratedSources/` | Generated `Types.swift` and `Client.swift`, checked into source control |
| `Sources/EudamedClient/EudamedClient.swift` | Convenience `Client()` initialiser (points at the EUDAMED server) |
| `Sources/EudamedClient/TypesExtensions.swift` | Convenience extensions on generated OpenAPI types |
| `Sources/EudamedDataModel/models/` | SwiftData `@Model` domain types (`Actor`, `UdiDevice`, `ReferenceEntry`) |
| `Sources/EudamedDataModel/Remote*.swift` | Remote repository implementations (live API + pagination) |
| `Sources/EudamedDataModel/Local*.swift` | Local repository implementations (SwiftData `@ModelActor`) |
| `Sources/EudamedDataModel/Caching*.swift` | Caching repository implementations (offline-first composition) |
| `Tests/EudamedClientTests/` | Unit tests for `EudamedClient` using a mock transport |
| `Tests/EudamedDataModelTests/` | Unit tests for local repositories (in-memory SwiftData) and a live integration test for `CachingUdiRepository` |

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

## Running live integration tests

The `CachingUdiRepositoryLiveTests` suite requires network access to the EUDAMED API and is skipped by default. Enable it by setting the `ENABLE_LIVE_TESTS` environment variable:

```sh
ENABLE_LIVE_TESTS=1 swift test --filter CachingUdiRepositoryLiveTests
```

## License

EudamedPublicSwift is available for **noncommercial use** under the
[PolyForm Noncommercial License 1.0.0](LICENSE). See [EULA.md](EULA.md)
for the full End User License Agreement, including restrictions on
commercial use.

For commercial licensing, contact thomas@kausch.li.
