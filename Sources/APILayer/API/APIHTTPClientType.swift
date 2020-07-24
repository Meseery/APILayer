import Foundation

public protocol APIHTTPClientType {
    public func dataTask(urlRequest: URLRequest, completion: @escaping ((Result<Data, APIError>) -> Void))
    public func downloadTask(url: String, completion: @escaping ((Result<URL, APIError>) -> Void))
    public func cancel()
}
