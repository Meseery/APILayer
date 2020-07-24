import Foundation

public class APIHTTPClient: APIHTTPClientType {
    
    typealias RequestResult = Result<Data, APIError>
    
    private var session: URLSession
    private var task: URLSessionTask?
    
    init(config: URLSessionConfiguration = URLSessionConfiguration.default) {
        self.session = URLSession(configuration: config)
    }
    
    public func cancel() {
        task?.cancel()
    }
    
    public func dataTask(urlRequest: URLRequest, completion: @escaping ((Result<Data, APIError>) -> Void)) {
        task = session.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                completion(Result.failure(APIError.apiError(error)))
                return
            }
            guard let data = data, let response = response as? HTTPURLResponse else {
                completion(Result.failure(APIError.emptyData))
                return
            }
            guard response.statusCode == 200 else {
                completion(Result.failure(APIError.invalidStatusCode(response.statusCode)))
                return
            }
            completion(Result.success(data))
        }
        task?.resume()
    }
    
    public func downloadTask(url: String, completion: @escaping ((Result<URL, APIError>) -> Void)) {
        guard let downloadURL = URL(string: url) else {
            completion(Result.failure(.invalidRequestURL(url)))
            return
        }
        task = session.downloadTask(with: downloadURL) { (url, respone, error) in
            if let error = error {
                completion(.failure(APIError.apiError(error)))
                return
            }
            guard let url = url else {
                completion(Result.failure(APIError.emptyData))
                return
            }
            completion(Result.success(url))
        }
        task?.resume()
    }
}
