import UIKit

public extension UIImageView {
    struct ImageView {
        static var imageURLKey: Void?
    }
    
    private var imageURL: String? {
        get {
            return objc_getAssociatedObject(self, &ImageView.imageURLKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &ImageView.imageURLKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public func load(url: String, indexPath: IndexPath) {
        if let previousURL = imageURL {
            ImageDownloadManager.shared.changeDownloadPriorityToSlow(of: previousURL)
        }
        imageURL = url
        ImageDownloadManager.shared.download(url: url, indexPath: indexPath, size: self.frame.size) { [weak self](image, url, indexPathh, error) in
            DispatchQueue.main.async {
                if let strongSelf = self, let image = image, let _path = strongSelf.imageURL, _path == url {
                    strongSelf.imageURL = nil
                    strongSelf.image = image
                }
            }
        }
    }
    
    public func load(url: String) {
        ImageDownloadManager.shared.download(url: url, indexPath: nil, size: self.frame.size) { (image, url, indexPathh, error) in
            if let image = image {
                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }
    }
    
    public func resizedImageWith(image: UIImage, targetSize: CGSize) -> UIImage? {
        return image.resizedImageWith(image: image, targetSize: targetSize)
    }
}
