# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Tethering is an iOS application that provides SOCKS5 proxy, DNS server, and HTTP PAC file hosting capabilities. Originally forked from an abandoned iPhone SOCKS proxy project, it enables network tethering functionality on iOS devices.

## Build and Development Commands

### Xcode Project
- **Main project**: Open `Tethering.xcodeproj` in Xcode
- **Build target**: Tethering.app for iOS
- **Main storyboard**: `Main.storyboard`
- **Info.plist**: Located at `Resources/Info.plist`

### DNS Component (ttdnsd)
The DNS server component has its own build system:

```bash
# Build DNS component
cd ttdnsd
./build.sh                    # Standard build
./build.sh HAVE_COCOA        # Build with Cocoa framework support

# Clean build artifacts
./clean.sh
```

The DNS component uses CMake:
- **CMakeLists.txt**: `ttdnsd/CMakeLists.txt`
- **Build output**: Creates `Console` and `stopConsole` executables

## Architecture Overview

### Core Components

1. **SocksProxyController** (`SocksProxyController.h/.mm`)
   - Main controller managing the SOCKS5 proxy service
   - Implements `SocksProxyDelegate` and `NSNetServiceDelegate`
   - Handles Bonjour service registration
   - Manages connection state and statistics

2. **SocksProxy** (`SocksProxy.h/.mm`)
   - Individual SOCKS5 connection handler
   - Implements stream-based proxy forwarding
   - Manages send/receive buffers (100KB send, 200KB receive)

3. **HTTPServer** (`WebServer/HTTPServer.h/.m`)
   - HTTP server for PAC file hosting (port 8080)
   - Provides automatic proxy configuration
   - Implements singleton pattern via `+sharedHTTPServer`

4. **DNS Server** (`ttdnsd/`)
   - TCP DNS daemon based on Tor's ttdnsd
   - Written in C++ with Objective-C++ wrapper
   - Handles DNS queries for the proxy setup

5. **WebServer Components**
   - **HTTPResponseHandler**: Handles individual HTTP requests
   - **PacFileResponse**: Serves PAC (Proxy Auto-Configuration) files

### Key Features

- **Bonjour Services**: Registers `_socks._tcp.`, `_http._tcp.`, `_nslogger._tcp` services
- **Background Audio**: Uses silent audio to maintain background execution
- **Network Permissions**: Requires local network access permission (iOS 14+)
- **Multi-platform UI**: Supports both iPhone and iPad orientations

### App Configuration

- **Bundle ID**: Configured via `$(PRODUCT_BUNDLE_IDENTIFIER)`
- **Version**: Currently 1.7 (defined in Info.plist)
- **Background Modes**: Audio playback for persistent operation
- **Network Services**: DNS (port varies), SOCKS5 (port varies), HTTP PAC (port 8080)

### Dependencies

- **System Frameworks**: UIKit, Foundation, CoreGraphics, QuartzCore, CFNetwork, SystemConfiguration, SafariServices, AVFoundation
- **Custom UI**: MOButton and MOGlassButton for enhanced button styling
- **Logging**: NSLogger integration for remote logging
- **Color Management**: ColorC utility for color operations

## File Organization

- **Root**: Main application files (controllers, proxies, utilities)
- **AncillaryCode/**: App delegate and main entry point
- **Resources/**: Assets, storyboard, Info.plist, launch screen
- **WebServer/**: HTTP server implementation
- **NSLogger/**: Remote logging framework
- **ttdnsd/**: DNS server component with separate build system

The project follows iOS app conventions with Objective-C++ implementation for core networking components.