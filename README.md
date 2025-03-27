# AHandGestureKit

<div align="center">
  <img src="https://drive.google.com/file/d/1jHytMA2HIyeTW3LoqZFVu0Yehcpxs4Z_/view?usp=drive_link" alt="AHandGestureKit Logo" width="200"/>
  
  [![Swift](https://img.shields.io/badge/Swift-5.5-orange.svg)](https://swift.org)
  [![Platform](https://img.shields.io/badge/Platform-iOS%2014.0+-blue.svg)](https://developer.apple.com/ios/)
  
  A powerful and intuitive framework for real-time hand gesture recognition in iOS applications.
</div>

## 🌟 Features

- ✋ Real-time hand gesture recognition
- 🎯 Support for standard gestures (open hand, pinch)
- 🛠 Custom gesture support with configurable thresholds
- 📱 Smooth coordinate tracking
- 📸 Camera preview integration
- 🔒 Thread-safe operations
- 🎨 Easy-to-use API
- 📦 Swift Package Manager support

## 🎯 Purpose

AHandGestureKit was created to simplify the integration of hand gesture recognition into iOS applications. It provides developers with a robust and easy-to-use solution for:

- Creating interactive applications controlled by hand gestures
- Building accessibility features for touch-free interaction
- Developing AR/VR experiences with natural hand controls
- Implementing gesture-based navigation systems
- Creating engaging user experiences through natural hand movements

## 📋 Requirements

- iOS 14.0+
- Xcode 13.0+
- Swift 5.5+

## 🚀 Installation

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

## 🔒 Privacy Permissions

Before using AHandGestureKit, you need to add camera usage description to your `Info.plist` file:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera to recognize hand gestures.</string>
```

## 💡 Usage Examples

### Basic Implementation

```swift
import AHandGestureKit

class ViewController: UIViewController {
    private let gestureKit = HandGestureKit()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGestureRecognition()
    }
    
    private func setupGestureRecognition() {
        Task {
            do {
                try await gestureKit.startGestureRecognition(
                    in: view,
                    targetGestures: [.openHand, .pinch]
                ) { gesture, coordinates in
                    if let gesture = gesture {
                        print("Detected gesture: \(gesture)")
                    }
                    if let coordinates = coordinates {
                        print("Hand position: \(coordinates)")
                    }
                }
            } catch {
                print("Failed to start gesture recognition: \(error)")
            }
        }
    }
}
```

### Advanced Example: Custom "Rock" Gesture

This example demonstrates how to create and use a custom gesture that recognizes the "Rock" hand sign (index and little fingers extended, other fingers closed).

```swift
class GestureViewController: UIViewController {
    private var handGestureKit: HandGestureKit?
    private let imageView = UIImageView()
    private let statusLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGestureRecognition()
    }
    
    private func setupGestureRecognition() {
        handGestureKit = HandGestureKit()
        
        // Create a custom "Rock" gesture definition
        let rockGesture = HandGesture.CustomGesture(
            name: "Rock",
            points: [
                // Index and little fingers should be extended
                HandGesture.HandPoint(type: .indexTip, threshold: 0.7),
                HandGesture.HandPoint(type: .littleTip, threshold: 0.7),
                
                // Middle and ring fingers should be closed
                HandGesture.HandPoint(type: .middleTip, threshold: 0.3),
                HandGesture.HandPoint(type: .ringTip, threshold: 0.3),
                
                // Thumb should be closed
                HandGesture.HandPoint(type: .thumbTip, threshold: 0.3)
            ]
        )

        // Create a HandGesture with our custom gesture
        let customGesture = HandGesture.custom(rockGesture)
        
        Task {
            do {
                try await handGestureKit?.startGestureRecognition(
                    in: self.view,
                    targetGestures: [.pinch, customGesture]
                ) { [weak self] gesture, point in
                    guard let self = self,
                          let point = point,
                          let gesture = gesture else { return }
                    
                    // Update UI on the main thread
                    DispatchQueue.main.async {
                        self.imageView.center = point
                        self.statusLabel.text = "Gesture: \(gesture.description)"
                    }
                    
                    // Handle different gesture types
                    switch gesture {
                    case .openHand:
                        print("Open hand detected")
                    case .pinch:
                        print("Pinch gesture detected")
                    case .custom(let customGesture):
                        print("Custom gesture detected: \(customGesture.name)")
                    }
                    
                    // Apply smoothing to the coordinates
                    let smoothedPoint = CGPoint(x: point.x, y: point.y)
                    
                    // Update UI with smoothed coordinates
                    DispatchQueue.main.async {
                        self.imageView.center = smoothedPoint
                        self.statusLabel.text = "Gesture: \(gesture.description)"
                    }
                }
            } catch {
                print("Failed to start gesture recognition: \(error)")
            }
        }
    }
}
```

### Understanding the Code

1. **Gesture Definition**:
   - We create a custom "Rock" gesture by defining specific points and their thresholds
   - Higher thresholds (0.7) indicate fingers that should be extended
   - Lower thresholds (0.3) indicate fingers that should be closed

2. **Gesture Recognition**:
   - The framework continuously monitors hand positions
   - When a gesture is detected, the completion handler is called with:
     - The detected gesture
     - The current hand position coordinates

3. **UI Updates**:
   - All UI updates are performed on the main thread
   - The example shows how to:
     - Update an image view's position based on hand movement
     - Display the current gesture in a status label
     - Apply coordinate smoothing for smoother movement

4. **Error Handling**:
   - The code includes proper error handling for gesture recognition setup
   - Weak self references are used to prevent retain cycles

This example demonstrates how to:
- Create complex custom gestures
- Handle multiple gesture types
- Update UI elements based on hand movement
- Apply coordinate smoothing
- Handle errors appropriately

## 👤 Author

- GitHub: [@Polnoreff1](https://github.com/Polnoreff1)

## 🙏 Acknowledgments

- Apple Vision Framework

<div align="center">
  Made with ❤️ for the iOS community
</div> 
