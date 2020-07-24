import Foundation
import UIKit

public class APIImageRequest {
    
    private var client: APIHTTPClientType
    
    init(client: APIHTTPClientType) {
        self.client = client
    }
    
    public func download(url: String, completion: @escaping (String, UIImage?, Error?) -> Void) {
        client.downloadTask(url: url) { (result) in
            switch result {
            case .success(let response):
                if let data = try? Data(contentsOf: response), let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        completion(url, image, nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(url, nil, APIError.somethingWentWrong)
                    }
                }
                break
                
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(url, nil, error)
                }

                break
            }
        }
    }
    
    public func cancel() {
        client.cancel()
    }
}
