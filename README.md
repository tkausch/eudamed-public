![EudamedPublicSwift](Eudamed.png)

A Swift package providing a type-safe client and in-memory caching layer for the [EUDAMED](https://ec.europa.eu/tools/eudamed/) public API.

EUDAMED is the IT system established by Regulation (EU) 2017/745 on medical devices and Regulation (EU) 2017/746 on in vitro diagnostic medical devices.

## Requirements

- Swift 5.9+
- macOS 14 / iOS 17 or later

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
| `EudamedCore` | Low-level OpenAPI-generated REST client. Use when you only need raw API access. |
| `EudamedClient` | Domain models (`Actor`, `UdiDevice`, `ReferenceEntry`) and remote repositories with automatic pagination. Reference data is cached in memory via `CachingReferenceRepository`. |

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

`EudamedClient` provides lightweight domain model structs and remote repositories with automatic pagination. Reference data has an additional in-memory caching layer used internally by `UdiDevice` to resolve reference IDs.

### Domain models

`Actor`, `UdiDevice`, and `ReferenceEntry` are plain `Sendable` structs that map directly from the EUDAMED API responses.

### Repositories

| Class | Description |
|---|---|
| `RemoteActorRepository` | Fetches actors from the live EUDAMED API, follows pagination automatically. |
| `RemoteUdiDevicesRepository` | Fetches UDI device records from the live EUDAMED API, follows pagination automatically. |
| `RemoteReferenceRepository` | Fetches reference/nomenclature data from the live EUDAMED API. |
| `CachingReferenceRepository` | In-memory actor-isolated cache for reference data; hits the remote on the first miss, then serves subsequent matching queries from memory. Used internally by `UdiDevice` to resolve reference IDs into human-readable labels. |

### Usage

```swift
import EudamedClient

// Actors — always fetches from the network with automatic pagination
let actorRepo = try RemoteActorRepository()
let actors = try await actorRepo.search(query: ActorQuery(name: "Acme"))

// UDI devices — always fetches from the network with automatic pagination
let udiRepo = try RemoteUdiDevicesRepository()
let devices = try await udiRepo.search(query: UdiDevicesQuery(deviceName: "catheter"))

// Reference data — remote
let remote = try RemoteReferenceRepository()
let entries = try await remote.search(query: ReferenceQuery(code: "refdata.risk-class.class-iii", language: "en"))

// Reference data — cached (first call fetches; subsequent matching queries are served from memory)
let repo = CachingReferenceRepository()
let cached = try await repo.search(query: ReferenceQuery(code: "refdata.risk-class.class-iii", language: "en"))
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
| `Sources/EudamedClient/models/` | Domain model structs (`Actor`, `UdiDevice`, `ReferenceEntry`) |
| `Sources/EudamedClient/Remote*.swift` | Remote repository implementations (live API + automatic pagination) |
| `Sources/EudamedClient/Caching*.swift` | In-memory caching repository for reference data |
| `Tests/EudamedRestTests/` | Unit tests for the REST client using a mock transport |
| `Tests/EudamedClientTests/` | Unit tests for remote and caching repositories |

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
