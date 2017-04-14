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

    public enum ExportError: MediaExporterError {
        case imageJPEGDataRepresentationFailed
        case imageSourceCreationWithDataFailed
        case imageSourceDestinationWithURLFailed
        case imageSourceDestinationWriteFailed
        var description: String {
            switch self {
            case .imageJPEGDataRepresentationFailed,
                 .imageSourceCreationWithDataFailed,
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
    /// - parameter onCompletion: Called on successful export, with the local file URL of the exported UIImage.
    /// - parameter onError: Called if an error was encountered during creation.
    ///
    func exportImage(_ image: UIImage, fileName: String?, onCompletion: @escaping (URL) -> (), onError: @escaping (MediaExporterError) -> ()) {
        do {
            guard let data = UIImageJPEGRepresentation(image, 1.0) else {
                throw ExportError.imageJPEGDataRepresentationFailed
            }
            exportImage(withJPEGData: data, fileName: fileName, onCompletion: onCompletion, onError: onError)
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }

    struct ImageSourceWriting {
        var fileName: String?
        var type: CFString
        var imagesCount = 0
        var imageIndex = 0
    }

    fileprivate func exportImage(withJPEGData data: Data, fileName: String?, onCompletion: @escaping (URL) -> (), onError: @escaping (MediaExporterError) -> ()) {

        let options: [String: Any] = [kCGImageSourceTypeIdentifierHint as String: kUTTypeJPEG]
        guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else {
            onError(ExportError.imageSourceCreationWithDataFailed)
            return
        }
        exportImageSource(source, fileName: fileName, onCompletion: onCompletion, onError: onError)
    }

    fileprivate func exportImageSource(_ source: CGImageSource, fileName: String?, onCompletion: @escaping (URL) -> (), onError: @escaping (MediaExporterError) -> ()) {

        if let type = CGImageSourceGetType(source), type == kUTTypeGIF {
            // write it directly
        }
    }

    fileprivate func writeImageSourceToMediaDirectory(_ source: CGImageSource, fileName: String?, type: CFString, onCompletion: @escaping (URL) -> (), onError: @escaping (MediaExporterError) -> ()) {
        do {
            let url = try MediaLibrary.makeLocalMediaURL(withFilename: fileName ?? defaultImageFilename, fileExtension: fileExtensionForUTType(type))
            guard let destination = CGImageDestinationCreateWithURL(url as CFURL, type, 1, nil) else {
                throw ExportError.imageSourceDestinationWithURLFailed
            }
            // let properties // exclude geo if needed
            CGImageDestinationAddImageFromSource(destination, source, 0, nil)
            let written = CGImageDestinationFinalize(destination)
            guard written == true else {
                throw ExportError.imageSourceDestinationWriteFailed
            }
            onCompletion(url)
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }

    fileprivate func fileExtensionForUTType(_ type: CFString) -> String? {
        let fileExtension = UTTypeCopyPreferredTagWithClass(type, kUTTagClassFilenameExtension)?.takeRetainedValue()
        return fileExtension as String?
    }
}
