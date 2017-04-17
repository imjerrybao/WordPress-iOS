import Foundation

/// Encapsulates interfacing with Media objects and their assets, whether locally on disk or remotely.
///
/// - Note: Methods with escaping closures will call back via the configured managedObjectContex.performBlock
///   method and it's corresponding thread.
///
open class MediaLibrary: LocalCoreDataService {

    /// Creates a Media object with an absoluteLocalURL for a PHAsset's data, asynchronously.
    ///
    /// - parameter onMedia: Called if the Media was successfully created and the asset's data exported to an absoluteLocalURL.
    /// - parameter onError: Called if an error was encountered during creation, error convertible to NSError with a localized description.
    ///
    public func makeMediaWith(blog: Blog, asset: PHAsset, onMedia: @escaping (Media) -> (), onError: ((Error) -> ())?) {
        DispatchQueue.global(qos: .default).async {
            let exporter = MediaPHAssetExporter()
            exporter.exportData(forAsset: asset, onCompletion: { (url) in
                self.managedObjectContext.perform {
                    let media = Media.makeMedia(blog: blog)
                    exporter.configure(media: media, withAsset: asset)
                    media.absoluteLocalURL = url
                    onMedia(media)
                }
            }, onError: { (error) in
                if let onError = onError {
                    self.managedObjectContext.perform {
                        let nerror = error.toNSError()
                        DDLogSwift.logError("Error occurred exporting Media with a PHAsset, code: \(nerror.code), error: \(nerror)")
                        onError(error.toNSError())
                    }
                }
            })
        }
    }

    /// Creates a Media object with a UIImage, asynchronously.
    ///
    /// The UIImage is expected to be a JPEG, PNG, or other 'normal' image.
    ///
    /// - parameter onMedia: Called if the Media was successfully created and the image's data exported to an absoluteLocalURL.
    /// - parameter onError: Called if an error was encountered during creation, error convertible to NSError with a localized description.
    ///
    public func makeMedia(blog: Blog, image: UIImage, onMedia: @escaping (Media) -> (), onError: ((Error) -> ())?) {
        DispatchQueue.global(qos: .default).async {
            let exporter = MediaImageExporter()
            exporter.exportImage(image, fileName: nil, onCompletion: { (url) in
                self.managedObjectContext.perform {
                    let media = Media.makeMedia(blog: blog)
                    media.mediaType = .image
                    media.absoluteLocalURL = url
                    onMedia(media)
                }
            }, onError: { (error) in
                if let onError = onError {
                    self.managedObjectContext.perform {
                        let nerror = error.toNSError()
                        DDLogSwift.logError("Error occurred exporting Media with a UIImage, code: \(nerror.code), error: \(nerror)")
                        onError(error.toNSError())
                    }
                }
            })
        }
    }

    /// Creates a Media object with a file at a URL, asynchronously.
    ///
    /// The file URL is expected to be a JPEG, PNG, GIF, other 'normal' image, or video.
    ///
    /// - parameter onMedia: Called if the Media was successfully created and the file's data exported to an absoluteLocalURL.
    /// - parameter onError: Called if an error was encountered during creation, error convertible to NSError with a localized description.
    ///
    public func makeMediaWith(blog: Blog, url: URL, onMedia: @escaping (Media) -> (), onError: ((Error) -> ())?) {
        DispatchQueue.global(qos: .default).async {
            let exporter = MediaURLExporter()
            exporter.exportURL(fileURL: url, onCompletion: { (url) in
                self.managedObjectContext.perform {
                    let media = Media.makeMedia(blog: blog)
                    media.mediaType = .image
                    media.absoluteLocalURL = url
                    onMedia(media)
                }
            }, onError: { (error) in
                if let onError = onError {
                    self.managedObjectContext.perform {
                        let nerror = error.toNSError()
                        DDLogSwift.logError("Error occurred exporting Media with a UIImage, code: \(nerror.code), error: \(nerror)")
                        onError(error.toNSError())
                    }
                }
            })
        }
    }
}
