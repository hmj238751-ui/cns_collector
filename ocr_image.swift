import Vision
import CoreImage
import Foundation

guard CommandLine.arguments.count > 1 else {
    print("Usage: swift ocr_image.swift <image_path>")
    exit(1)
}

let path = CommandLine.arguments[1]
guard let img = CIImage(contentsOf: URL(fileURLWithPath: path)) else {
    print("ERROR: Cannot load \(path)")
    exit(1)
}

let semaphore = DispatchSemaphore(value: 0)
let request = VNRecognizeTextRequest { request, error in
    defer { semaphore.signal() }
    if let error = error { print("Error: \(error)"); return }
    guard let obs = request.results as? [VNRecognizedTextObservation] else { return }
    for o in obs.prefix(20) {
        if let t = o.topCandidates(1).first { print(t.string) }
    }
}
request.recognitionLevel = .accurate
request.recognitionLanguages = ["en-US", "zh-Hans"]
try? VNImageRequestHandler(ciImage: img).perform([request])
semaphore.wait()
