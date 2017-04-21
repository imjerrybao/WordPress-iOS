import XCTest
@testable import WordPress
import MobileCoreServices

class MediaExporterTests: XCTestCase {

    // MARK: - Image export testing

    func testThatImageExportingByImageWorks() {
        guard let mediaPath = OHPathForFile("test-image-device-photo-gps.jpg", type(of: self)) else {
            XCTAssert(false, "Error: failed creating a path to the test image file")
            return
        }
        guard let image = UIImage(contentsOfFile: mediaPath) else {
            XCTFail("Error: an error occurred initializing the test image for export")
            return
        }
        let expect = self.expectation(description: "image export by UIImage")
        let exporter = MediaImageExporter()
        exporter.mediaDirectoryType = .temporary
        exporter.stripsGeoLocationIfNeeded = false
        exporter.exportImage(image,
                             fileName: nil,
                             onCompletion: { (imageExport) in
                                self.cleanUpExportedMedia(atURL: imageExport.url)
                                expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing an image export: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testThatImageExportingByURLWorks() {
        guard let mediaPath = OHPathForFile("test-image-device-photo-gps.jpg", type(of: self)) else {
            XCTAssert(false, "Error: failed creating a path to the test image file")
            return
        }
        let expect = self.expectation(description: "image export by URL")
        let url = URL(fileURLWithPath: mediaPath)
        let exporter = MediaImageExporter()
        exporter.mediaDirectoryType = .temporary
        exporter.stripsGeoLocationIfNeeded = false
        exporter.exportImage(atURL: url,
                             onCompletion: { (imageExport) in
                                self.cleanUpExportedMedia(atURL: imageExport.url)
                                expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing an image export: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testThatImageExportingWithResizingWorks() {
        guard let mediaPath = OHPathForFile("test-image-device-photo-gps.jpg", type(of: self)) else {
            XCTAssert(false, "Error: failed creating a path to the test image file")
            return
        }
        let expect = self.expectation(description: "image export with a maximum size")
        let url = URL(fileURLWithPath: mediaPath)
        let exporter = MediaImageExporter()
        let maximumImageSize = CGFloat(200)
        exporter.mediaDirectoryType = .temporary
        exporter.maximumImageSize = maximumImageSize
        exporter.stripsGeoLocationIfNeeded = false
        exporter.exportImage(atURL: url,
                             onCompletion: { (imageExport) in
                                self.validateImageExport(imageExport, withExpectedSize: maximumImageSize)
                                self.cleanUpExportedMedia(atURL: imageExport.url)
                                expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing an image export by URL with a maximum size: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    fileprivate func validateImageExport(_ imageExport: MediaImageExport, withExpectedSize expectedSize: CGFloat) {
        guard let image = UIImage(contentsOfFile: imageExport.url.path) else {
            XCTFail("Error: an error occurred checking the image from an export")
            return
        }
        let maxDimension = max(image.size.width, image.size.height)
        if maxDimension > expectedSize {
            XCTFail("Error: the exported image was larger than the expected maximum size: (\(image.size))")
        }
        if let exportWidth = imageExport.width {
            XCTAssertTrue(exportWidth == image.size.width, "Error: the exported image's width did not match the imageExport's width value: (\(exportWidth))")
        } else {
            XCTFail("Error: the imageExport's width value was nil")
        }
        if let exportHeight = imageExport.height {
            XCTAssertTrue(exportHeight == image.size.height, "Error: the exported image's height did not match the imageExport's height value: (\(exportHeight))")
        } else {
            XCTFail("Error: the imageExport's height value was nil")
        }
    }

    // MARK: - Image export GPS testing

    func testThatImageExportingAndStrippingGPSWorks() {
        guard let mediaPath = OHPathForFile("test-image-device-photo-gps.jpg", type(of: self)) else {
            XCTAssert(false, "Error: failed creating a path to the test image file")
            return
        }
        let expect = self.expectation(description: "image export with stripping GPS")
        let url = URL(fileURLWithPath: mediaPath)
        let exporter = MediaImageExporter()
        exporter.mediaDirectoryType = .temporary
        exporter.stripsGeoLocationIfNeeded = true
        exporter.exportImage(atURL: url,
                             onCompletion: { (imageExport) in
                                self.validateImageExportStrippedGPS(imageExport)
                                self.cleanUpExportedMedia(atURL: imageExport.url)
                                expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing an image export and stripping GPS: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testThatImageExportingAndDidNotStripGPSWorks() {
        guard let mediaPath = OHPathForFile("test-image-device-photo-gps.jpg", type(of: self)) else {
            XCTAssert(false, "Error: failed creating a path to the test image file")
            return
        }
        let expect = self.expectation(description: "image export without stripping GPS")
        let url = URL(fileURLWithPath: mediaPath)
        let exporter = MediaImageExporter()
        exporter.mediaDirectoryType = .temporary
        exporter.stripsGeoLocationIfNeeded = false
        exporter.exportImage(atURL: url,
                             onCompletion: { (imageExport) in
                                self.validateImageExportDidNotStripGPS(imageExport)
                                self.cleanUpExportedMedia(atURL: imageExport.url)
                                expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing an image export and not stripping GPS: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testThatImageExportingWithResizingAndStrippingGPSWorks() {
        guard let mediaPath = OHPathForFile("test-image-device-photo-gps.jpg", type(of: self)) else {
            XCTAssert(false, "Error: failed creating a path to the test image file")
            return
        }
        let expect = self.expectation(description: "image export with resizing and stripping GPS")
        let url = URL(fileURLWithPath: mediaPath)
        let exporter = MediaImageExporter()
        let maximumImageSize = CGFloat(200)
        exporter.mediaDirectoryType = .temporary
        exporter.stripsGeoLocationIfNeeded = true
        exporter.maximumImageSize = maximumImageSize
        exporter.exportImage(atURL: url,
                             onCompletion: { (imageExport) in
                                self.validateImageExportStrippedGPS(imageExport)
                                self.validateImageExport(imageExport, withExpectedSize: maximumImageSize)
                                self.cleanUpExportedMedia(atURL: imageExport.url)
                                expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing an image export with resizing and stripping GPS: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testThatImageExportingWithResizingAndNotStrippingGPSWorks() {
        guard let mediaPath = OHPathForFile("test-image-device-photo-gps.jpg", type(of: self)) else {
            XCTAssert(false, "Error: failed creating a path to the test image file")
            return
        }
        let expect = self.expectation(description: "image export with resizing and stripping GPS")
        let url = URL(fileURLWithPath: mediaPath)
        let exporter = MediaImageExporter()
        let maximumImageSize = CGFloat(200)
        exporter.mediaDirectoryType = .temporary
        exporter.stripsGeoLocationIfNeeded = false
        exporter.maximumImageSize = maximumImageSize
        exporter.exportImage(atURL: url,
                             onCompletion: { (imageExport) in
                                self.validateImageExportDidNotStripGPS(imageExport)
                                self.validateImageExport(imageExport, withExpectedSize: maximumImageSize)
                                self.cleanUpExportedMedia(atURL: imageExport.url)
                                expect.fulfill()
        }) { (error) in
            XCTFail("Error: an error occurred testing an image export with resizing and not stripping GPS: \(error.toNSError())")
            expect.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    fileprivate func validateImageExportStrippedGPS(_ imageExport: MediaImageExport) {
        guard let source = CGImageSourceCreateWithURL(imageExport.url as CFURL, nil) else {
            XCTFail("Error: an error occurred checking the image source from an export")
            return
        }
        guard let properties: [String: Any] = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? Dictionary else {
            XCTFail("Error: an error occurred checking an image source's properties from an export")
            return
        }
        if properties[kCGImagePropertyGPSDictionary as String] != nil {
            XCTFail("Error: found GPS properties when reading an exported image source's properties")
        }
    }

    fileprivate func validateImageExportDidNotStripGPS(_ imageExport: MediaImageExport) {
        guard let source = CGImageSourceCreateWithURL(imageExport.url as CFURL, nil) else {
            XCTFail("Error: an error occurred checking the image source from an export")
            return
        }
        guard let properties: [String: Any] = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? Dictionary else {
            XCTFail("Error: an error occurred checking an image source's properties from an export")
            return
        }
        if properties[kCGImagePropertyGPSDictionary as String] == nil {
            XCTFail("Error: did not find expected GPS properties when reading an exported image source's properties")
        }
    }

    // MARK: - Image export testing cleanup

    fileprivate func cleanUpExportedMedia(atURL url: URL) {
        do {
            let fileManager = FileManager.default
            try fileManager.removeItem(at: url)
        } catch {
            XCTFail("Error: failed to clean up exported media: \(error)")
        }
    }

    // MARK: - Error testing

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

    // MARK: - Helper testing

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
