import Foundation

extension Media {

    /// Creates and returns a Media object, configured with a URL.
    ///
    class func with(url: URL, context: NSManagedObjectContext) -> Media {
        let media = makeMedia(in: context)
        return media
    }
}
