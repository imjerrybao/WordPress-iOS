import XCTest
@testable import WordPress
import MobileCoreServices

class MediaExporterTests: XCTestCase {

    func testExporterErrorsWork() {

        let sampleLocalizedString = "This was an error test"
        let mockSystemError = NSError(domain: "MediaExporterTests", code: 999, userInfo: [NSLocalizedDescriptionKey: sampleLocalizedString])
        let exportSystemError = MediaExportSystemError.failedWith(systemError: mockSystemError)

        // Test that the descriptions are being interpreted correctly.
        XCTAssert(exportSystemError.description == String(describing: mockSystemError), "Error: unexpected description text for MediaExportSystemError")
        XCTAssert(exportSystemError.toNSError().localizedDescription == sampleLocalizedString, "Error: unexpected localizedDescription from NSError method via MediaExportSystemError")

        // General testing via MediaImageExporter and MediaImageExporter.ExportError, can use any of the exporters or errors.
        let exporter = MediaImageExporter()
        let imageError = MediaImageExporter.ExportError.imageSourceCreationWithDataFailed

        // Test that the type values are being carried over correctly when using exporterErrorWith(error:)
        let isEqual: Bool
        switch exporter.exporterErrorWith(error: imageError) {
        case MediaImageExporter.ExportError.imageSourceCreationWithDataFailed:
            isEqual = true
        default:
            isEqual = false
        }
        XCTAssert(isEqual, "Error: unexpected type value encountered when wrapping a known MediaExportError as a MediaExportError")

        // Test that the localizedDescriptions are being interpreted correctly.
        XCTAssert(imageError.toNSError().localizedDescription == imageError.description, "Error: unexpected localizedDescription when reading converting to an NSError")

        // Test that the types are being carried over correctly when using exporterErrorWith(error:) with an NSError.
        let generalError = imageError.toNSError() as Error
        let generalErrorWrappedAsAnExporterError = exporter.exporterErrorWith(error: generalError)

        XCTAssert(generalErrorWrappedAsAnExporterError.toNSError().isEqual(generalError), "Error: unexpected NSError generated while wrapping within a MediaExportError")
    }

    func testThatFileExtensionForTypeIsWorking() {
        // Testing JPEG as a simple test of the implementation.
        // Maybe expanding the test to all of our supported types would be helpful.
        let exporter = MediaImageExporter()
        let expected = "jpeg"
        XCTAssert(exporter.fileExtensionForUTType(kUTTypeJPEG as String) == expected, "Error: unexpected extension found when converting from UTType")
    }

    func testThatFileSizeAtURLWorks() {
        guard let mediaPath = OHPathForFile("test-image.jpg", type(of: self)) else {
            XCTAssert(false, "Error: failed creating a path to the test image file")
            return
        }
        let url = URL(fileURLWithPath: mediaPath)
        let exporter = MediaImageExporter()
        guard let size = exporter.fileSizeAtURL(url) else {
            XCTAssert(false, "Error: failed getting a size of the test image file")
            return
        }
        XCTAssert(size == 233139, "Error: unexpected file size found for the test image: \(size)")
    }
}
