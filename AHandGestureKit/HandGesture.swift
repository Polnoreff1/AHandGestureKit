//
//  HandGesture.swift
//  AHandGestureKit
//
//  Created by Andrei Versta on 26/3/25.
//

import Foundation
import Vision

/// Represents different types of hand gestures that can be detected.
public enum HandGesture: Equatable {
    case openHand
    case pinch
    case custom(CustomGesture)
    
    /// Represents a custom gesture definition that can be created by users
    public struct CustomGesture: Equatable {
        /// Unique name for the custom gesture
        public let name: String
        /// Array of points that define the gesture
        public let points: [HandPoint]
        
        public init(name: String, points: [HandPoint]) {
            self.name = name
            self.points = points
        }
    }
    
    /// Represents a single point in a custom gesture that needs to be checked
    public struct HandPoint: Equatable {
        /// The type of hand joint to check (e.g., .indexTip, .thumbTip, etc.)
        public let type: VNHumanHandPoseObservation.JointName
        /// The confidence threshold for this point (0.0 to 1.0)
        public let threshold: CGFloat
        
        public init(type: VNHumanHandPoseObservation.JointName, threshold: CGFloat) {
            self.type = type
            self.threshold = threshold
        }
    }
    
    public var description: String {
        switch self {
        case .openHand:
            return "Open Hand"
        case .pinch:
            return "Pinch"
        case .custom(let gesture):
            return gesture.name
        }
    }
    
    public static func == (lhs: HandGesture, rhs: HandGesture) -> Bool {
        switch (lhs, rhs) {
        case (.openHand, .openHand),
             (.pinch, .pinch):
            return true
        case (.custom(let gesture1), .custom(let gesture2)):
            return gesture1.name == gesture2.name
        default:
            return false
        }
    }
}

/*
 Example of creating and using a custom gesture:
 
 // 1. Create a custom gesture definition
 let fistGesture = HandGesture.CustomGesture(
     name: "Fist",
     points: [
         // Check if all fingers are close to the wrist (bent)
         HandGesture.HandPoint(type: .indexTip, threshold: 0.3),
         HandGesture.HandPoint(type: .middleTip, threshold: 0.3),
         HandGesture.HandPoint(type: .ringTip, threshold: 0.3),
         HandGesture.HandPoint(type: .littleTip, threshold: 0.3),
         HandGesture.HandPoint(type: .thumbTip, threshold: 0.3)
     ]
 )
 
 // 2. Create a HandGesture with your custom gesture
 let customGesture = HandGesture.custom(fistGesture)
 
 // 3. Use it with HandGestureKit
 let gestureKit = HandGestureKit()
 try await gestureKit.startGestureRecognition(
     in: view,
     targetGestures: [.pinch, customGesture]
 ) { gesture, point in
     if let gesture = gesture {
         switch gesture {
         case .pinch:
             print("Pinch detected")
         case .custom(let customGesture):
             if customGesture.name == "Fist" {
                 print("Fist detected!")
             }
         default:
             break
         }
     }
 }
 
 Available joint types for custom gestures:
 - .wrist - wrist
 - .thumbCMC - thumb base joint
 - .thumbMCP - thumb middle joint
 - .thumbIP - thumb tip joint
 - .thumbTip - thumb tip
 - .indexMCP - index finger base joint
 - .indexPIP - index finger middle joint
 - .indexDIP - index finger upper joint
 - .indexTip - index finger tip
 - .middleMCP - middle finger base joint
 - .middlePIP - middle finger middle joint
 - .middleDIP - middle finger upper joint
 - .middleTip - middle finger tip
 - .ringMCP - ring finger base joint
 - .ringPIP - ring finger middle joint
 - .ringDIP - ring finger upper joint
 - .ringTip - ring finger tip
 - .littleMCP - little finger base joint
 - .littlePIP - little finger middle joint
 - .littleDIP - little finger upper joint
 - .littleTip - little finger tip
 */
