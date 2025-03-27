//
//  CameraManager.swift
//  AHandGestureKit
//
//  Created by Andrei Versta on 26/3/25.
//

import AVFoundation

/// Protocol for handling camera output
public protocol CameraManagerDelegate: AnyObject {
    /// Called when a new sample buffer is available from the camera
    /// - Parameter sampleBuffer: The CMSampleBuffer containing the camera frame
    func didOutputSampleBuffer(_ sampleBuffer: CMSampleBuffer)
}

/// Manages camera capture and video processing
public class CameraManager: NSObject {
    /// The capture session for handling camera input
    public var captureSession: AVCaptureSession!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    /// The current camera position
    private var cameraPosition: AVCaptureDevice.Position = .front
    
    /// Delegate to handle camera output
    public weak var delegate: CameraManagerDelegate?
    
    /// Initializes a new CameraManager instance
    public override init() {
        super.init()
        setupCamera()
    }
    
    /// Sets up the camera capture session with the specified configuration
    private func setupCamera() {
        captureSession?.stopRunning()
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition) else {
            print("Error: Camera not found.")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            let videoOutput = AVCaptureVideoDataOutput()
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        } catch {
            print("Error setting up camera: \(error)")
        }
    }
}

/// Extension to handle camera output
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    /// Called when a new sample buffer is available
    /// - Parameters:
    ///   - output: The capture output that produced the sample buffer
    ///   - sampleBuffer: The CMSampleBuffer containing the camera frame
    ///   - connection: The connection from which the sample buffer was received
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.didOutputSampleBuffer(sampleBuffer)
    }
}

import Vision

/// Handles gesture recognition using Vision framework
public class GestureRecognizer {
    
    /// The Vision request for detecting hand poses
    public var handPoseRequest: VNDetectHumanHandPoseRequest!
    private var customGestures: [HandGesture.CustomGesture] = []
    
    /// Initializes a new GestureRecognizer instance
    public init() {
        handPoseRequest = VNDetectHumanHandPoseRequest()
    }
    
    /// Sets the custom gestures to be recognized
    /// - Parameter gestures: Array of custom gesture definitions
    public func setCustomGestures(_ gestures: [HandGesture.CustomGesture]) {
        self.customGestures = gestures
    }
    
    /// Processes hand pose observations to detect gestures
    /// - Parameter observations: Array of hand pose observations from Vision framework
    /// - Returns: Detected gesture if any, nil otherwise
    public func processHandPose(_ observations: [VNHumanHandPoseObservation]) -> HandGesture? {
        guard let hand = observations.first else { return nil }
        
        if let indexTip = try? hand.recognizedPoint(.indexTip),
           let middleTip = try? hand.recognizedPoint(.middleTip),
           let ringTip = try? hand.recognizedPoint(.ringTip),
           let littleTip = try? hand.recognizedPoint(.littleTip),
           let wrist = try? hand.recognizedPoint(.wrist) {
            
            let fingers = [indexTip, middleTip, ringTip, littleTip]
            let isSpread = fingers.allSatisfy { finger in
                let distanceToWrist = distanceBetween(finger, wrist)
                return distanceToWrist > 0.1
            }
            
            let fingersSpread = fingers.allSatisfy { finger in
                let distances = fingers.filter { $0 != finger }.map { otherFinger in
                    distanceBetween(finger, otherFinger)
                }
                return distances.allSatisfy { $0 > 0.1 }
            }
            
            if isSpread && fingersSpread {
                return .openHand
            }
        }
        
        if let thumbTip = try? hand.recognizedPoint(.thumbTip),
           let indexTip = try? hand.recognizedPoint(.indexTip) {
            let pinchDistance = distanceBetween(thumbTip, indexTip)
            if pinchDistance < 0.1 {
                return .pinch
            }
        }
        
        for gesture in customGestures {
            if processCustomGesture(gesture, in: hand) {
                return .custom(gesture)
            }
        }
        
        return nil
    }
    
    /// Processes a custom gesture against a hand pose observation
    /// - Parameters:
    ///   - gesture: The custom gesture to check
    ///   - hand: The hand pose observation to check against
    /// - Returns: True if the gesture is detected, false otherwise
    public func processCustomGesture(_ gesture: HandGesture.CustomGesture, in hand: VNHumanHandPoseObservation) -> Bool {
        // Проверяем все точки кастомного жеста
        return gesture.points.allSatisfy { point in
            guard let recognizedPoint = try? hand.recognizedPoint(point.type) else {
                return false
            }
            
            return recognizedPoint.confidence >= Float(point.threshold)
        }
    }
    
    /// Calculates the distance between two recognized points
    /// - Parameters:
    ///   - point1: First point
    ///   - point2: Second point
    /// - Returns: The Euclidean distance between the points
    private func distanceBetween(_ point1: VNRecognizedPoint, _ point2: VNRecognizedPoint) -> CGFloat {
        let dx = point1.location.x - point2.location.x
        let dy = point1.location.y - point2.location.y
        return sqrt(dx * dx + dy * dy)
    }
}
