import Foundation

/// Encapsulates interfacing with Media objects and their assets, whether locally on disk or remotely.
///
open class MediaLibrary: LocalCoreDataService {

    func makeMediaWith(blog: Blog, asset: PHAsset, onMedia: @escaping (Media) -> (), onError: ((Error) -> ())?) {
    }

    func makeMedia(blog: Blog, image: UIImage, onMedia: @escaping (Media) -> (), onError: ((Error) -> ())?) {
    }

    func makeMediaWith(blog: Blog, video: URL, onMedia: @escaping (Media) -> (), onError: ((Error) -> ())?) {
    }

    fileprivate lazy var backgroundManagedObjectContext: NSManagedObjectContext = {
        let background = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        background.parent = self.managedObjectContext
        background.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return background
    }()
}


fileprivate extension MediaLibrary {

    static let defaultFilename = "image"

    enum ExportingError: Error {
        case failed(reason: String)
    }

    func exportData(forImage asset: PHAsset, onCompletion: @escaping (URL) -> (), onError: @escaping (Error) -> ()) {
        assert(asset.mediaType == .image, "PHAsset was not the expected image type")
        do {
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            let manager = PHAssetResourceManager.default()
            let resources = PHAssetResource.assetResources(for: asset).filter { (resource) -> Bool in
                // Note: we may want to instead use .fullSizePhoto or .fullSizeVideo when uploading to sites.
                // The user may be more interested in always uploading/optimizing from the full size assets versus whatever
                // the resource returns for .photo
                return resource.type == .photo
            }
            if let photo = resources.first {
                let filename = photo.originalFilename
                let url = try MediaLibrary.makeLocalMediaURL(withFilename: filename, fileExtension: nil)
                manager.writeData(for: photo,
                                  toFile: url,
                                  options: options,
                                  completionHandler: { (error) in
                                    if let error = error {
                                        onError(error)
                                        return
                                    }
                                    onCompletion(url)
                })
            } else {
                throw ExportingError.failed(reason: "Failed to access and export the device photo.")
            }
        } catch {
            DDLogSwift.logError("Error: encountered an error while exporting a photo's data from a PHAsset: \(error.localizedDescription)")
            onError(error)
        }
    }

    func exportData(forVideo asset: PHAsset) {

    }
}
