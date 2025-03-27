# ``AHandGestureKit``

A powerful and easy-to-use framework for hand gesture recognition using Apple's Vision framework.

## Overview

AHandGestureKit is a Swift framework that enables real-time hand gesture recognition in iOS applications. It provides a simple interface for detecting various hand gestures and tracking hand movements using the device's camera.

### Features

- Real-time hand gesture recognition
- Support for standard gestures (open hand, pinch)
- Custom gesture support with configurable thresholds
- Smooth coordinate tracking
- Camera preview integration
- Thread-safe operations
- Easy-to-use API

### Requirements

- iOS 14.0+
- Xcode 13.0+
- Swift 5.5+

## Topics

### Getting Started

- ``HandGestureKit``
- ``HandGesture``
- ``HandGestureError``

### Core Components

- ``CameraManager``
- ``GestureRecognizer``

### Gesture Types

- ``HandGesture/openHand``
- ``HandGesture/pinch``
- ``HandGesture/custom(_:)``

### Custom Gestures

- ``HandGesture/CustomGesture``
- ``HandGesture/HandPoint``

## Example Usage

```swift
import AHandGestureKit

// Initialize the gesture kit
let gestureKit = HandGestureKit()

// Start gesture recognition
try await gestureKit.startGestureRecognition(
    in: yourView,
    targetGestures: [.openHand, .pinch]
) { gesture, coordinates in
    if let gesture = gesture {
        print("Detected gesture: \(gesture)")
    }
    if let coordinates = coordinates {
        print("Hand position: \(coordinates)")
    }
}
```

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/Polnoreff1/AHandGestureKit.git", from: "1.0.0")
]
```

### Manual Installation

1. Download the latest release
2. Drag `AHandGestureKit.xcodeproj` into your project
3. Add the framework to your target's dependencies

## License

AHandGestureKit is available under the MIT license. See the LICENSE file for more info.
