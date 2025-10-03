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
    /// Whether to run in continuous batch scanning mode.
    var batchMode: Bool = false

    /// Called every time a card-like text is detected in batch mode.
    /// If nil, falls back to `onScannedText`.
    var onCardFound: ((String) -> Void)? = nil

    /// Callback function when text is recognized and selected (non-batch flow)
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

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        /// Reference to the parent view to access callbacks
        let parent: CardScannerView
        
        // Deduplication window per recognized name so we don't spam the same card
        private var lastHitTimes: [String: Date] = [:]
        private let minInterval: TimeInterval = 1.5
        
        init(parent: CardScannerView) {
            self.parent = parent
        }

        private func handleRecognizedText(_ raw: String, scanner: DataScannerViewController) {
            let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return }
            
            if parent.batchMode {
                let now = Date()
                if let last = lastHitTimes[text], now.timeIntervalSince(last) < minInterval {
                    return
                }
                lastHitTimes[text] = now
                if let onCardFound = parent.onCardFound {
                    onCardFound(text)
                } else {
                    parent.onScannedText(text)
                }
                // Stay in scanning mode for batch flow
            } else {
                parent.onScannedText(text)
                scanner.stopScanning()
                parent.onFinish()
            }
        }

        /// Handles user taps on recognized text items (single-pick flow)
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: VisionKit.RecognizedItem) {
            if case .text(let recognizedText) = item {
                handleRecognizedText(recognizedText.transcript, scanner: dataScanner)
            }
        }

        /// Stream new items as they appear (batch flow)
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [VisionKit.RecognizedItem], allItems: [VisionKit.RecognizedItem]) {
            guard parent.batchMode else { return }
            for item in addedItems {
                if case .text(let recognizedText) = item {
                    handleRecognizedText(recognizedText.transcript, scanner: dataScanner)
                }
            }
        }

        /// Stream updated items as they stabilize (batch flow)
        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [VisionKit.RecognizedItem], allItems: [VisionKit.RecognizedItem]) {
            guard parent.batchMode else { return }
            for item in updatedItems {
                if case .text(let recognizedText) = item {
                    handleRecognizedText(recognizedText.transcript, scanner: dataScanner)
                }
            }
        }

        /// Handles scanning errors
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
