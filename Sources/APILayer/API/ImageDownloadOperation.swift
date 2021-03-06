import UIKit

public class ImageDownloadOperation: Operation {
    
    private var request: APIImageRequest?
    private var downloadTask: URLSessionTask?
    
    public var downloadCompletionHandler: ImageDownloadManager.ImageDownloadHandler?

    private(set) var imagePath: String
    private let size: CGSize
    private let indexPath: IndexPath?
    
    private let cacheDir: URL
    private let fileManager: FileManager
    
    init(url: String, size: CGSize, indexPath: IndexPath?, cacheDir: URL, fileManager: FileManager) {
        self.imagePath = url
        self.size = size
        self.indexPath = indexPath
        self.cacheDir = cacheDir
        self.fileManager = fileManager
    }
    
    public override func main() {
        guard isCancelled == false else {
            finish(true)
            return
        }
        executing(true)
        load()
    }
    
    public override func cancel() {
        request?.cancel()
    }
    
    public override var isExecuting: Bool {
        return backExecuting
    }
    
    private var backExecuting: Bool = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    public override var isFinished: Bool {
        return backFinished
    }
    
    private var backFinished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    private func executing(_ executing: Bool) {
        backExecuting = executing
    }
    
    private func finish(_ finished: Bool) {
        backFinished = finished
    }
    
    private func download() {
        request = APIImageRequest(client: APIHTTPClient())
        request?.download(url: imagePath) { [weak self] (location, image, error) in
            self?.completed(image: image, error: error)
            self?.finish(true)
            self?.executing(false)
        }
    }
    
    private func completed(image: UIImage?, error: Error?) {
        self.downloadCompletionHandler?(image, imagePath, indexPath, error as? APIError)
    }
    
    private func fileLoadcompleted(image: UIImage?) {
        if !isCancelled {
            downloadCompletionHandler?(image, imagePath, indexPath, nil)
            finish(true)
            executing(false)
        }
    }
    
    private func load() {
        let fileName = imagePath.components(separatedBy: "/").last!
        let originalFile = cacheDir.appendingPathComponent("\(fileName)")
        let scaleFile = cacheDir.appendingPathComponent("\(fileName)\(size.width)x\(size.height)")
        
        if fileManager.fileExists(atPath: scaleFile.relativePath),
            let data = try? Data(contentsOf: scaleFile),
            let image = UIImage(data: data),
            let scaledImage = image.resizedImageWith(image: image, targetSize: size)  {
            
            fileLoadcompleted(image: scaledImage)
            
        } else if fileManager.fileExists(atPath: originalFile.relativePath),
            let data = try? Data(contentsOf: originalFile),
            let image = UIImage(data: data),
            let scaleImage = image.resizedImageWith(image: image, targetSize: size)  {
            
            cacheImage(originalImage: nil, scaledImage: scaleImage)
            fileLoadcompleted(image: image)
            
        } else {
            download()
        }
    }

    private func cacheImage(originalImage: UIImage?, scaledImage: UIImage?) {
        let fileName = imagePath.components(separatedBy: "/").last!
        let originalFile = self.cacheDir.appendingPathComponent("\(fileName)")
        let scaleFile = self.cacheDir.appendingPathComponent("\(fileName)\(size.width)x\(size.height)")
        
        if let origImage = originalImage, !self.fileManager.fileExists(atPath: originalFile.relativePath) {
            try? origImage.jpegData(compressionQuality: 1)?.write(to: originalFile)
        }
        
        if let scaleImage = scaledImage, !self.fileManager.fileExists(atPath: scaleFile.relativePath) {
            try? scaleImage.jpegData(compressionQuality: 1)?.write(to: scaleFile)
        }
    }
}
