# CLAUDE.md

This file guides Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Bagel is a tool that helps iOS developers debug web request calls.  It does this without being a proxy, so requires no advanced proxy setup.  It is intended only for understanding the requests going and out the responses coming back into the app.  There is purely a monitoring tool, no manipulation.

It consists of 3 main pieces:

### Library

The library (in the `iOS` folder) is written in Objective C, and it uses swizzling to inject itself into the private API of the standard Apple-provided URL loading mechanisms.  It gathers data about what is requested of these libraries, and what is sent back from these libraries.  It then packages those up, and sends them to the Mac app.  It uses Bonjour / mDNS (in the case of a physical device) or connects to a specific localhost port (in the case of a simulator) and sends the data over the network to the Mac Console for display.

### Mac Console

The Mac Console (in the `mac` folder) is the main view of the app.  The Mac Console app must be open before the Bagel library is used in an app during development.  It opens a network port and advertises that port using Bonjour / mDNS.  When it receives a packet, it displays information about the request for the user to inspect.  The information is divied up in the UI by the Device and the Project of the packet, so the console can monitor multiple devices / projects at once.

### Test / POC App

The Test / POC app (in the `test` folder) is a simple reference implentation and test platform for the project.  It has several sample calls you can make to test their display in the Mac Console.  This is included mainly for development, however, so the libary and Mac Console app can be developed independently of another outside codebase.

## Build Commands

Use `build.sh` to clean and build each component:

- `./build.sh mac` — Build the Mac Console app
- `./build.sh library` — Build the iOS library
- `./build.sh test` — Build the Test / POC app
