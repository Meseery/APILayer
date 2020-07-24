import Foundation

public protocol APIHTTPClientType {
    func dataTask(urlRequest: URLRequest, completion: @escaping ((Result<Data, APIError>) -> Void))
    func downloadTask(url: String, completion: @escaping ((Result<URL, APIError>) -> Void))
    func cancel()
}
