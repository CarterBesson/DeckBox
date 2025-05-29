//
//  CardScannerView.swift
//  DeckBox
//
//  Created by Carter Besson on 5/25/25.
//

// MARK: - Card Scanner View
/// A view that uses the device camera and Vision framework to scan and recognize card names.
/// Implements text recognition using VisionKit's DataScannerViewController.
/// Users can tap on recognized text to select the card name they want to add.

import SwiftUI
import VisionKit

/// A SwiftUI wrapper around UIKit's DataScannerViewController for text recognition
struct CardScannerView: UIViewControllerRepresentable {
    /// Callback function when text is recognized and selected
    /// - Parameter String: The recognized text (card name)
    var onScannedText: (String) -> Void
    
    /// Callback function when the scanning session ends
    /// Called after successful text selection or on error
    var onFinish: () -> Void

    /// Creates and configures the DataScannerViewController
    func makeUIViewController(context: Context) -> DataScannerViewController {
        // Configure scanner for printed text recognition with high accuracy
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    /// Updates the scanner view controller when SwiftUI updates
    /// Ensures scanning is started when the view appears
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // Start scanning when view appears if not already scanning
        if !uiViewController.isScanning {
            do {
                try uiViewController.startScanning()
            } catch {
                print("Failed to start scanning: \(error)")
            }
        }
    }

    /// Creates the coordinator to handle scanner delegate callbacks
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    /// Coordinator class to handle DataScannerViewController delegate methods
    /// Manages communication between UIKit scanner and SwiftUI view
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        /// Reference to the parent view to access callbacks
        let parent: CardScannerView
        
        init(parent: CardScannerView) {
            self.parent = parent
        }

        /// Handles user taps on recognized text items
        /// When text is tapped, passes the recognized text to the callback
        /// and ends the scanning session
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: VisionKit.RecognizedItem) {
            switch item {
            case .text(let recognizedText):
                let name = recognizedText.transcript
                parent.onScannedText(name)
                dataScanner.stopScanning()
                parent.onFinish()
            default:
                break
            }
        }

        /// Handles scanning errors
        /// Stops the scanning session and notifies the parent view
        func dataScanner(_ dataScanner: DataScannerViewController, didFailWithError error: Error) {
            print("DataScanner error: \(error)")
            dataScanner.stopScanning()
            parent.onFinish()
        }
    }
}

/// Preview provider for CardScannerView
/// Demonstrates basic usage with text recognition logging
#Preview {
    CardScannerView(onScannedText: { text in
        print("Scanned: \(text)")
    }, onFinish: {})
}
