import Foundation
import MobileCoreServices

/// MediaLibrary export handling of UIImages.
///
class MediaImageExporter: MediaExporter {

    /// Default filename used when writing media images locally, which may be appended with "-1" or "-thumbnail".
    ///
    let defaultImageFilename = "image"

    var resizesIfNeeded = true
    var stripsGeoLocationIfNeeded = true

    public enum ExportError: MediaExportError {
        case imageJPEGDataRepresentationFailed
        case imageSourceCreationWithDataFailed
        case imageSourceCreationWithURLFailed
        case imageSourceIsAnUnknownType
        case imageSourceExpectedJPEGImageType
        case imageSourceDestinationWithURLFailed
        case imageSourceDestinationWriteFailed
        var description: String {
            switch self {
            case .imageJPEGDataRepresentationFailed,
                 .imageSourceCreationWithDataFailed,
                 .imageSourceCreationWithURLFailed,
                 .imageSourceIsAnUnknownType,
                 .imageSourceExpectedJPEGImageType,
                 .imageSourceDestinationWithURLFailed,
                 .imageSourceDestinationWriteFailed:
                return NSLocalizedString("The image could not be added to the Media Library.", comment: "Message shown when an image failed to load while trying to add it to the Media library.")
            }
        }
        func toNSError() -> NSError {
            return NSError(domain: _domain, code: _code, userInfo: [NSLocalizedDescriptionKey: String(describing: self)])
        }
    }

    /// Exports and writes a UIImage to a local Media URL.
    ///
    /// A JPEG or PNG is expected, but not necessarily required. Exporting will fail if a JPEG cannot
    /// be represented from the UIImage, such as trying to export a GIF.
    ///
    /// - parameter fileName: Filename if it's known.
    /// - parameter onCompletion: Called on successful export, with the local file URL of the exported UIImage.
    /// - parameter onError: Called if an error was encountered during creation.
    ///
    func exportImage(_ image: UIImage, fileName: String?, onCompletion: @escaping (MediaImageExport) -> (), onError: @escaping (MediaExportError) -> ()) {
        do {
            guard let data = UIImageJPEGRepresentation(image, 1.0) else {
                throw ExportError.imageJPEGDataRepresentationFailed
            }
            exportImage(withJPEGData: data, fileName: fileName, onCompletion: onCompletion, onError: onError)
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }

    /// Exports and writes an image's data, expected as JPEG format, to a local Media URL.
    ///
    /// - parameter fileName: Filename if it's known.
    /// - parameter onCompletion: Called on successful export, with the local file URL of the exported UIImage.
    /// - parameter onError: Called if an error was encountered during creation.
    ///
    func exportImage(withJPEGData data: Data, fileName: String?, onCompletion: @escaping (MediaImageExport) -> (), onError: @escaping (MediaExportError) -> ()) {
        do {
            let options: [String: Any] = [kCGImageSourceTypeIdentifierHint as String: kUTTypeJPEG]
            guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else {
                throw ExportError.imageSourceCreationWithDataFailed
            }
            guard let utType = CGImageSourceGetType(source) else {
                throw ExportError.imageSourceIsAnUnknownType
            }
            guard UTTypeEqual(utType, kUTTypeJPEG) else {
                throw ExportError.imageSourceExpectedJPEGImageType
            }
            exportImageSource(source, filename: fileName, type:utType as String, onCompletion: onCompletion, onError: onError)
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }

    /// Exports and writes image data located at a URL, to a local Media URL.
    ///
    /// A JPEG or PNG is expected, but not necessarily required. The export will write the same data format
    /// as found at the URL, or will throw if the type is unknown or fails.
    ///
    /// - parameter onCompletion: Called on successful export, with the local file URL of the exported UIImage.
    /// - parameter onError: Called if an error was encountered during creation.
    ///
    func exportImage(atURL url: URL, onCompletion: @escaping (MediaImageExport) -> (), onError: @escaping (MediaExportError) -> ()) {
        do {
            let options: [String: Any] = [kCGImageSourceTypeIdentifierHint as String: kUTTypeJPEG]
            guard let source = CGImageSourceCreateWithURL(url as CFURL, options as CFDictionary)  else {
                throw ExportError.imageSourceCreationWithURLFailed
            }
            guard let utType = CGImageSourceGetType(source) else {
                throw ExportError.imageSourceIsAnUnknownType
            }
            exportImageSource(source, filename: url.deletingPathExtension().lastPathComponent, type:utType as String, onCompletion: onCompletion, onError: onError)
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }

    /// Exports and writes an image source, to a local Media URL.
    ///
    /// - parameter fileName: Filename if it's known.
    /// - parameter onCompletion: Called on successful export, with the local file URL of the exported UIImage.
    /// - parameter onError: Called if an error was encountered during creation.
    ///
    func exportImageSource(_ source: CGImageSource, filename: String?, type: String, onCompletion: @escaping (MediaImageExport) -> (), onError: @escaping (MediaExportError) -> ()) {
        do {
            let filename = filename ?? defaultImageFilename
            // Make a new URL within the local Media directory
            let url = try MediaLibrary.makeLocalMediaURL(withFilename: filename,
                                                         fileExtension: fileExtensionForUTType(type))

            // Check MediaSettings and configure the image writer as needed.
            let mediaSettings = MediaSettings()
            var writer = ImageSourceWriter(url: url, sourceUTType: type as CFString)
            if stripsGeoLocationIfNeeded {
                writer.nullifyGPSData = mediaSettings.removeLocationSetting
            }
            if resizesIfNeeded {
                let mediaSettingsUploadSize = mediaSettings.imageSizeForUpload
                if mediaSettingsUploadSize < Int.max {
                    writer.maximumSize = mediaSettingsUploadSize as CFNumber
                }
            }
            let result = try writer.writeImageSource(source)
            onCompletion(MediaImageExport(url: url,
                                          width: result.width,
                                          height: result.height,
                                          fileSize: result.fileSize))
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }

    /// Configureable struct around writing an image to a URL from a CGImageSource via CGImageDestination, particular to the needs of MediaImageExporter.
    ///
    /// - parameter url: File URL where the image should be written
    /// - parameter sourceUTType: The UTType of the image source
    /// - parameter lossyCompressionQuality: The Compression quality used, defaults to 1.0 or full
    /// - parameter nullifyGPSData: Whether or not GPS data should be nullified.
    /// - parameter maximumSize: A maximum size required for the image to be written, or nil.
    ///
    fileprivate struct ImageSourceWriter {

        var url: URL
        var sourceUTType: CFString
        var lossyCompressionQuality = 1.0 as CFNumber
        var nullifyGPSData = false
        var maximumSize: CFNumber?

        init(url: URL, sourceUTType: CFString) {
            self.url = url
            self.sourceUTType = sourceUTType
        }

        struct WriteResultProperties {
            let width: CGFloat?
            let height: CGFloat?
            let fileSize: Int64?
        }

        /// Write a given image source, succeeds unless an error is thrown, returns the resulting properties if available.
        ///
        func writeImageSource(_ source: CGImageSource) throws -> WriteResultProperties {
            // Create the destination with the URL, or error
            guard let destination = CGImageDestinationCreateWithURL(url as CFURL, sourceUTType, 1, nil) else {
                throw ExportError.imageSourceDestinationWithURLFailed
            }

            // Configure desired image properties for CGImageDestinationAddImageFromSource
            var imageProperties: [String: Any] = [:]
            imageProperties[kCGImageDestinationLossyCompressionQuality as String] = lossyCompressionQuality

            if nullifyGPSData == true {
                // Not sure if this is all that's required
                imageProperties[kCGImagePropertyGPSDictionary as String] = kCFNull
            }

            var sourceImageIndex = 0
            if let maximumSize = maximumSize {
                // Create a thumbnail of the image source, and use it at the primary image to write to the destination
                let thumbnailOptions: [String: Any] = [kCGImageSourceThumbnailMaxPixelSize as String: maximumSize]
                CGImageSourceCreateThumbnailAtIndex(source, 1, thumbnailOptions as CFDictionary)
                sourceImageIndex = 1
            }

            CGImageDestinationAddImageFromSource(destination, source, sourceImageIndex, imageProperties as CFDictionary)

            // Write the image to the file URL
            let written = CGImageDestinationFinalize(destination)
            guard written == true else {
                throw ExportError.imageSourceDestinationWriteFailed
            }

            let sourceProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? Dictionary<String, AnyObject>

            let width: CGFloat? = sourceProperties?[kCGImagePropertyPixelWidth as String] as? CGFloat
            let height: CGFloat? = sourceProperties?[kCGImagePropertyPixelHeight as String] as? CGFloat
            let fileSize: Int64? = sourceProperties?[kCGImagePropertyFileSize as String] as? Int64

            return WriteResultProperties(width: width, height: height, fileSize: fileSize)
        }
    }
}
