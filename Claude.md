# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Bagel is a non-proxy iOS network debugger. The iOS library intercepts URLSession and NSURLConnection calls via method swizzling and streams packet data over TCP to the Mac Console for display. No proxy setup required — it monitors without modifying traffic.

It consists of 3 components:

- **`iOS/`** — Objective-C library, uses swizzling to intercept URLSession/NSURLConnection
- **`mac/`** — Swift Mac Console app, listens on TCP port 43434, displays captured requests
- **`test/`** — SwiftUI test/POC app that uses the library to generate sample traffic

## Build Commands

Use `build.sh` to clean and build each component:

```bash
./build.sh mac        # Build the Mac Console app (uses xcworkspace + CocoaPods)
./build.sh library    # Build the iOS library (simulator)
./build.sh test       # Build the Test/POC app (simulator)
```

Run Mac app unit tests:
```bash
xcodebuild -workspace mac/Bagel.xcworkspace -scheme Bagel test
```

The Mac app uses CocoaPods (`mac/Podfile`) — only dependency is `Highlightr` for JSON syntax highlighting. If Pods are missing, run `pod install` in `mac/`.

The iOS library is also distributed as a Swift Package (`Package.swift` at root, target name `Bagel`, source path `iOS/Source`).

## Architecture

### Data Flow

```
iOS app (Bagel library)
  → swizzle URLSession / NSURLConnection
  → BagelURLSessionInjector / BagelURLConnectionInjector (delegate callbacks)
  → BagelController (iOS) packages BagelRequestPacket
  → BagelBrowser (Bonjour discovery for device) or direct localhost for simulator
  → TCP: binary frame [UInt64 length][JSON body] (bodies are Base64-encoded)
Mac Console
  → BagelPublisher (NWListener on port 43434)
  → BagelController (Mac) decodes JSON → BagelPacket
  → BagelProjectController → BagelDeviceController → packet list
  → NSNotificationCenter events drive UI updates
  → Projects → Devices → Packets → Detail views
```

### Mac Console internals (`mac/Bagel/`)

The Mac app uses an MVC + ViewModel pattern. Cross-component communication is done exclusively via `NSNotificationCenter` — look for `BagelNotifications` constants when tracing data flow.

Key structural layers:
- **Workers/BagelController/** — network listener (`BagelPublisher`), packet hierarchy (`BagelController` → `BagelProjectController` → `BagelDeviceController`), and data models
- **Workers/ContentRepresentation/** — transforms raw packet data into displayable forms (cURL, overview, key-value lists, JSON/text/image body parsing)
- **Components/** — UI split into `Projects`, `Devices`, `Packets`, and `Details` components, each with its own ViewController + ViewModel

### iOS Library internals (`iOS/Source/`)

- `Bagel.h/m` — public singleton entry point (`[Bagel start]`)
- `BagelController` — coordinates injectors and manages the device/project context
- `BagelURLSessionInjector` / `BagelURLConnectionInjector` — swizzle the respective APIs; delegate callbacks capture request and response data
- `BagelBrowser` — Bonjour/mDNS discovery to find the Mac Console on the network
- Models: `BagelRequestInfo` → `BagelRequestCarrier` → `BagelRequestPacket` (outermost, sent over wire)
