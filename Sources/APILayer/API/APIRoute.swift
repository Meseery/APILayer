import Foundation

public class APIRoute {
    
    private(set) var urlPath: String = ""
    private(set) var method: HTTPMethod = .get
    private(set) var encoding: HttpEncoding = HttpEncoding.ParameterEncoding
    
    init(path: String, method: HTTPMethod, encoding: HttpEncoding) {
        self.urlPath = path
        self.method = method
        self.encoding = encoding
    }
    
    static func getRoute(path: String) -> APIRoute {
        return APIRoute(path: path, method: .get, encoding: HttpEncoding.ParameterEncoding)
    }
    
    static func postRoute(path: String) -> APIRoute {
        return APIRoute(path: path, method: .post, encoding: HttpEncoding.JSONEncoding)
    }
}
