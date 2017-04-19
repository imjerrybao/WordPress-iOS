import Foundation

/// Encapsulates interfacing with Media objects and their assets, whether locally on disk or remotely.
///
/// - Note: Methods with escaping closures will call back via the configured managedObjectContex.performBlock
///   method and it's corresponding thread.
///
open class MediaLibrary: LocalCoreDataService {

    // MARK: - Instance methods

    /// Creates a Media object with an absoluteLocalURL for a PHAsset's data, asynchronously.
    ///
    /// - parameter onMedia: Called if the Media was successfully created and the asset's data exported to an absoluteLocalURL.
    /// - parameter onError: Called if an error was encountered during creation, error convertible to NSError with a localized description.
    ///
    public func makeMediaWith(blog: Blog, asset: PHAsset, onMedia: @escaping (Media) -> (), onError: ((Error) -> ())?) {
        DispatchQueue.global(qos: .default).async {
            let exporter = MediaAssetExporter()
            exporter.exportData(forAsset: asset, onCompletion: { (assetExport) in
                self.managedObjectContext.perform {

                    let media = Media.makeMedia(blog: blog)
                    self.configureMedia(media, withExport: assetExport)
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
            exporter.exportImage(image, fileName: nil, onCompletion: { (imageExport) in
                self.managedObjectContext.perform {

                    let media = Media.makeMedia(blog: blog)
                    self.configureMedia(media, withExport: imageExport)
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
            exporter.exportURL(fileURL: url, onCompletion: { (urlExport) in
                self.managedObjectContext.perform {

                    let media = Media.makeMedia(blog: blog)
                    self.configureMedia(media, withExport: urlExport)
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

    // MARK: - Media export configurations


    /// Configure Media with the AssetExport.
    ///
    fileprivate func configureMedia(_ media: Media, withExport export: MediaAssetExporter.AssetExport) {
        switch export {
        case .exportedImage(let imageExport):
            configureMedia(media, withExport: imageExport)
        case .exportedVideo(let videoExport):
            configureMedia(media, withExport: videoExport)
        case .exportedGIF(let gifExport):
            configureMedia(media, withExport: gifExport)
        }
    }

    /// Configure Media with the URLExport.
    ///
    fileprivate func configureMedia(_ media: Media, withExport export: MediaURLExporter.URLExport) {
        switch export {
        case .exportedImage(let imageExport):
            configureMedia(media, withExport: imageExport)
        case .exportedVideo(let videoExport):
            configureMedia(media, withExport: videoExport)
        case .exportedGIF(let gifExport):
            configureMedia(media, withExport: gifExport)
        }
    }

    /// Configure Media with the ImageExport.
    ///
    fileprivate func configureMedia(_ media: Media, withExport export: MediaImageExport) {
        if let width = export.width {
            media.width = width as NSNumber
        }
        if let height = export.height {
            media.height = height as NSNumber
        }
        media.mediaType = .image
        configureMedia(media, withExport: export)
    }

    /// Configure Media with the VideoExport.
    ///
    fileprivate func configureMedia(_ media: Media, withExport export: MediaVideoExport) {
        if let duration = export.duration {
            media.length = duration as NSNumber
        }
        media.mediaType = .video
        configureMedia(media, withExport: export)
    }

    /// Configure Media with the GIFExport.
    ///
    fileprivate func configureMedia(_ media: Media, withExport export: MediaGIFExport) {
        media.mediaType = .image
        configureMedia(media, withExport: export)
    }

    /// Configure Media via the general Export protocol.
    ///
    fileprivate func configureMedia(_ media: Media, withExport export: MediaExport) {
        if let fileSize = export.fileSize {
            media.filesize = fileSize as NSNumber
        }
        media.absoluteLocalURL = export.url
    }
}
