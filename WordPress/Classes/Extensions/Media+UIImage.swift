import Foundation

extension Media {

    /// Creates and returns a Media object, configured with a UIImage.
    ///
    class func makeMedia(withImage image: UIImage, context: NSManagedObjectContext) -> Media {
        let media = makeMedia(in: context)
        media.mediaType = .image
        return media
    }
}
