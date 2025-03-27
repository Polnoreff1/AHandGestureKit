//
//  HandGestureKit.swift
//  AHandGestureKit
//
//  Created by Andrei Versta on 26/3/25.
//

import AVFoundation
import Vision
import UIKit

/// Main class for hand gesture recognition using Vision framework
public class HandGestureKit: CameraManagerDelegate {
    private var cameraManager: CameraManager!
    private var gestureRecognizer: GestureRecognizer!
    private var targetView: UIView?
    private var gestureCompletion: ((HandGesture?, CGPoint?) -> Void)?
    private var lastPoint: CGPoint = .zero
    private var isStarting: Bool = false
    private var viewWidth: CGFloat = 0
    private var viewHeight: CGFloat = 0
    private var targetGestures: [HandGesture] = []
    
    /// Initializes a new HandGestureKit instance
    public init() {
        cameraManager = CameraManager()
        gestureRecognizer = GestureRecognizer()
        cameraManager.delegate = self
    }
    
    /// Starts gesture recognition in the specified view
    /// - Parameters:
    ///   - view: The view to display camera preview and receive gesture coordinates
    ///   - targetGestures: Array of gestures to recognize. If not specified, all gestures will be recognized
    ///   - completion: Closure called when a gesture is detected or coordinates are updated
    /// - Throws: HandGestureError if recognition is already starting
    public func startGestureRecognition(
        in view: UIView,
        targetGestures: [HandGesture] = [.openHand, .pinch],
        completion: @escaping (HandGesture?, CGPoint?) -> Void
    ) async throws {
        // Check if recognition is already starting
        guard !isStarting else {
            throw HandGestureError.alreadyStarting
        }
        
        isStarting = true
        
        // Setup camera asynchronously on main thread
        await MainActor.run {
            self.targetView = view
            self.gestureCompletion = completion
            self.lastPoint = .zero
            self.targetGestures = targetGestures
            
            // Extract custom gestures and pass them to GestureRecognizer
            let customGestures = targetGestures.compactMap { gesture -> HandGesture.CustomGesture? in
                if case .custom(let customGesture) = gesture {
                    return customGesture
                }
                return nil
            }
            self.gestureRecognizer.setCustomGestures(customGestures)
            
            // Store view dimensions on main thread
            self.viewWidth = view.bounds.width
            self.viewHeight = view.bounds.height
        }
        
        // Start capture session in background
        await Task.detached(priority: .userInitiated) {
            self.cameraManager.captureSession?.startRunning()
        }.value
        
        isStarting = false
    }
    
    /// Stops gesture recognition and cleans up resources
    public func stopGestureRecognition() {
        Task { @MainActor in
            cameraManager.captureSession?.stopRunning()
            self.targetView = nil
            self.gestureCompletion = nil
            self.lastPoint = .zero
            self.targetGestures = []
        }
    }
    
    /// Handles new camera frame and processes gestures
    /// - Parameter sampleBuffer: The CMSampleBuffer containing the camera frame
    public func didOutputSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let completion = gestureCompletion else { return }
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try requestHandler.perform([self.gestureRecognizer.handPoseRequest])
            if let results = self.gestureRecognizer.handPoseRequest.results {
                let detectedGesture = self.gestureRecognizer.processHandPose(results)
                let coordinates = self.getGestureCoordinates(results)
                
                if let coordinates = coordinates, let targetView = targetView {
                    // Convert and smooth coordinates
                    let convertedPoint = convertCoordinates(coordinates, to: targetView)
                    let smoothedPoint = smoothCoordinates(convertedPoint)
                    
                    // Check if detected gesture is in target gestures
                    if let gesture = detectedGesture, targetGestures.contains(gesture) {
                        completion(gesture, smoothedPoint)
                    } else {
                        completion(nil, smoothedPoint)
                    }
                } else {
                    completion(nil, nil)
                }
            }
        } catch {
            print("Error processing frame: \(error)")
            completion(nil, nil)
        }
    }
    
    /// Extracts gesture coordinates from hand pose observations
    /// - Parameter observations: Array of hand pose observations
    /// - Returns: Center point of the palm if available, nil otherwise
    private func getGestureCoordinates(_ observations: [VNHumanHandPoseObservation]) -> CGPoint? {
        guard let hand = observations.first else { return nil }
        
        guard let wrist = try? hand.recognizedPoint(.wrist),
              let indexMCP = try? hand.recognizedPoint(.indexMCP),
              let middleMCP = try? hand.recognizedPoint(.middleMCP),
              let ringMCP = try? hand.recognizedPoint(.ringMCP),
              let littleMCP = try? hand.recognizedPoint(.littleMCP) else {
            return nil
        }
        
        // Calculate palm center point
        let palmX = (wrist.location.x + indexMCP.location.x + middleMCP.location.x + ringMCP.location.x + littleMCP.location.x) / 5
        let palmY = (wrist.location.y + indexMCP.location.y + middleMCP.location.y + ringMCP.location.y + littleMCP.location.y) / 5
        
        return CGPoint(x: palmX, y: palmY)
    }
    
    /// Converts normalized coordinates to view coordinates
    /// - Parameters:
    ///   - point: Normalized point (0-1 range)
    ///   - view: Target view for coordinate conversion
    /// - Returns: Converted point in view coordinates
    private func convertCoordinates(_ point: CGPoint, to view: UIView) -> CGPoint {
        // Use cached view dimensions
        let convertedX = (1 - point.y) * viewWidth  // Invert Y for X
        let convertedY = point.x * viewHeight       // Use X for Y
        
        return CGPoint(x: convertedX, y: convertedY)
    }
    
    /// Applies smoothing to coordinates to reduce jitter
    /// - Parameter point: Current point to smooth
    /// - Returns: Smoothed point
    private func smoothCoordinates(_ point: CGPoint) -> CGPoint {
        // Apply smoothing with 80% previous point and 20% current point
        let smoothedX = (lastPoint.x * 0.8) + (point.x * 0.2)
        let smoothedY = (lastPoint.y * 0.8) + (point.y * 0.2)
        
        // Update last point
        lastPoint = CGPoint(x: smoothedX, y: smoothedY)
        
        return lastPoint
    }
}

public enum HandGestureError: Error {
    case alreadyStarting
    case cameraNotAvailable
    case invalidConfiguration
}
