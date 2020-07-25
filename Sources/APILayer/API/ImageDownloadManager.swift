import UIKit

public class ImageDownloadManager {
    
    public static let shared = ImageDownloadManager()
    
    public typealias ImageDownloadHandler = (_ image: UIImage?, _ url: String, _ indexPath: IndexPath?, _ error: APIError?) -> Void

    lazy var imageDownloadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "com.moviedb.imagedownloadqueue"
        queue.qualityOfService = .userInteractive
        return queue
    }()
    
    lazy var diskCacheQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "com.moviedb.diskcachequeue"
        queue.qualityOfService = .userInteractive
        return queue
    }()
    
    private let imageCache = NSCache<NSString, UIImage>()
    private let cacheDir: URL
    private let fileManager: FileManager
    
    private init() {
        imageCache.totalCostLimit = 250 * 1024 * 1024
        fileManager = FileManager.default
        cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("moviesdb")
        try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true, attributes: nil)
    }
    
    public func download(url: String, indexPath: IndexPath?, size: CGSize, completion: @escaping ImageDownloadHandler) {
        if url.isEmpty {
            return
        }
        
        let requiredUrl = "\(url)\(size.width)x\(size.height)"
        
        if let cachedImage = imageCache.object(forKey: requiredUrl as NSString) {
            completion(cachedImage, url, indexPath, nil)
        } else {
            
            if let ongoingOperation = imageDownloadQueue.operations as? [ImageDownloadOperation],
                let imgOperation = ongoingOperation.first(where: {
                    return ($0.imagePath == url) && $0.isExecuting && !$0.isFinished
                }) {
                imgOperation.queuePriority = .high
            } else {
                addToOperation(url: url, indexPath: indexPath, size: size, completion: completion)
            }
            
        }
    }
    
    private func addToOperation(url: String, indexPath: IndexPath?, size: CGSize, completion: @escaping ImageDownloadHandler) {
        let imageOperation = ImageDownloadOperation(url: url, size: size, indexPath: indexPath, cacheDir: cacheDir, fileManager: fileManager)
        imageOperation.queuePriority = .veryHigh
        imageOperation.downloadCompletionHandler = { [unowned self] (image, url, indexPath, error) in
            if let image = image,
                let scaledImage = image.resizedImageWith(image: image, targetSize: size) {
                let requiredUrl = "\(url)\(size.width)x\(size.height)"
                self.cacheImage(originalImage: image, scaledImage: scaledImage, url: url, size: size)
                self.imageCache.setObject(scaledImage, forKey: requiredUrl as NSString)
                completion(image, url, indexPath, error)
            }
        }
        imageDownloadQueue.addOperation(imageOperation)
    }
    
    private func cacheImage(originalImage: UIImage?, scaledImage: UIImage?, url: String, size: CGSize) {
        DispatchQueue.global(qos: .background).async {
            let fileName = url.components(separatedBy: "/").last!
            let originalFile = self.cacheDir.appendingPathComponent("\(fileName)")
            let scaleFile = self.cacheDir.appendingPathComponent("\(fileName)\(size.width)x\(size.height)")
            
            if let origImage = originalImage, !self.fileManager.fileExists(atPath: originalFile.relativePath) {
                try? origImage.jpegData(compressionQuality: 1)?.write(to: originalFile)
            }
            
            if let _scaleImage = scaledImage, !self.fileManager.fileExists(atPath: scaleFile.relativePath) {
                try? _scaleImage.jpegData(compressionQuality: 1)?.write(to: scaleFile)
            }
        }
    }
    
    public func changeDownloadPriorityToSlow(of url: String) {
        guard let ongoingOpertions = imageDownloadQueue.operations as? [ImageDownloadOperation] else {
            return
        }
        let imageOperations = ongoingOpertions.filter {
            $0.imagePath == url && !$0.isFinished && $0.isExecuting
        }
        guard let operation = imageOperations.first else {
            return
        }
        operation.queuePriority = .low
    }
    
    public func cancelAll() {
        imageDownloadQueue.cancelAllOperations()
    }
    
    public func cancelOperation(imageUrl: String) {
        if let imageOperations = imageDownloadQueue.operations as? [ImageDownloadOperation],
            let operation = imageOperations.first(where: { $0.imagePath == imageUrl }) {
            operation.cancel()
        }
    }
}
