import Foundation

extension Media {

    /// Creates and returns a Media object, configured with a PHAsset.
    ///
    class func makeMedia(withAsset asset: PHAsset, blog: Blog) -> Media {
        let media = makeMedia(blog: blog)
        media.setMediaTypeWith(asset.mediaType)
        media.width = asset.pixelWidth as NSNumber
        media.height = asset.pixelHeight as NSNumber
        return media
    }

    /// Set mediaType with the PHAssetMediaType
    ///
    fileprivate func setMediaTypeWith(_ assetType: PHAssetMediaType) {
        switch assetType {
        case .image:
            mediaType = .image
        case .video:
            mediaType = .video
        default:
            mediaType = .document
        }
    }
}
