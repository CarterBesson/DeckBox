//
//  CardScannerView.swift
//  DeckBox
//
//  Created by Carter Besson on 5/25/25.
//

import SwiftUI
import VisionKit

struct CardScannerView: UIViewControllerRepresentable {
    /// Called when text is recognized (e.g., card name)
    var onScannedText: (String) -> Void
    /// Called when scanning session ends
    var onFinish: () -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        // Configure scanner for printed text recognition
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // Start scanning when view appears
        if !uiViewController.isScanning {
            do {
                try uiViewController.startScanning()
            } catch {
                print("Failed to start scanning: \(error)")
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: CardScannerView
        init(parent: CardScannerView) {
            self.parent = parent
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: VisionKit.RecognizedItem) {
            // Handle tapped recognized text
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

        func dataScanner(_ dataScanner: DataScannerViewController, didFailWithError error: Error) {
            print("DataScanner error: \(error)")
            dataScanner.stopScanning()
            parent.onFinish()
        }
    }
}

#Preview {
    // Simple preview that prints recognized text
    CardScannerView(onScannedText: { text in
        print("Scanned: \(text)")
    }, onFinish: {})
}
