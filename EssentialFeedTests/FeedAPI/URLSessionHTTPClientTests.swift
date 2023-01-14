//
//  Copyright © 2023. Viesure. All rights reserved.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (HttpClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error {
                completion(.failure(error))
            }
        }.resume()
    }
}

class URLSEssionHTTPClientTests: XCTestCase {
    
    func test_getFromURL_failsOnRequestError() {
        URLProtocolStub.startIntercepringRequest()
        let url = URL(string: "https://google.com")!
        let error = NSError(domain: "any error", code: 1, userInfo: [:])
        URLProtocolStub.stub(url: url, error: error)
        
        let sut = URLSessionHTTPClient()
        
        let expectation = expectation(description: "wait for completion")
        sut.get(from: url) { result in
            switch result {
            case let .failure(resceivedError as NSError):
                XCTAssertEqual(resceivedError.code, error.code)
                XCTAssertEqual(resceivedError.domain, error.domain)
            default:
                XCTFail("expected failure with error \(error) got result instead")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
        
        URLProtocolStub.stopIntercepringRequest()
    }
    
    // MARK: - HElpers
    
    private class URLProtocolStub: URLProtocol {
        
        private struct Stub {
            let error: Error?
        }
        
        private static var stubs = [URL: Stub]()

        
        static func stub(url: URL, error: Error? = nil) {
            stubs[url] = Stub(error: error)
        }
        
        static func startIntercepringRequest() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopIntercepringRequest() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            guard let url = request.url else { return false }
            
            return stubs[url] != nil
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }
        
        override func startLoading() {
            guard
                let url = request.url,
                let stub = Self.stubs[url]
            else { return }
            
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}
