# EudamedPublic

A Swift package providing a type-safe client for the [EUDAMED](https://ec.europa.eu/tools/eudamed/) public API, generated from an OpenAPI specification using [swift-openapi-generator](https://github.com/apple/swift-openapi-generator).

EUDAMED is the IT system established by Regulation (EU) 2017/745 on medical devices and Regulation (EU) 2017/746 on in vitro diagnostic medical devices.

## Requirements

- Swift 5.9+

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/tkausch/eudamedPublic", branch: "main")
]
```

Then add `EudamedClient` as a dependency of your target.

## Usage

```swift
import EudamedClient

let client = try Client()

let response = try await client.getActors(.init(query: .init(NAME: "Acme")))
```

Available operations:

| Operation | Path | Description |
|---|---|---|
| `getActors` | `/actors` | Search economic operators (manufacturers, authorized representatives, importers, etc.) |
| `getReference` | `/reference` | Look up reference/nomenclature data |
| `getUdi` | `/udi` | Search Unique Device Identification (UDI) records |

## Project layout

- `Sources/EudamedClient/openapi.yaml` — the source OpenAPI specification used by the generator plugin (`operationId`s renamed from raw UUIDs to readable names: `getActors`, `getReference`, `getUdi`)
- `Sources/EudamedClient/openapi-generator-config.yaml` — generator configuration (`types`, `client`, public access modifier)
- `Sources/EudamedClient/EudamedClient.swift` — convenience initializer

Generated `Types.swift`, `Client.swift`, and `Server.swift` are produced at build time by the `swift-openapi-generator` build plugin and are not checked into source control.

## Building

```sh
swift build
```
