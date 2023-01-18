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
    
    override func setUp() {
        URLProtocolStub.startIntercepringRequest()
    }
    
    override func tearDown() {
        URLProtocolStub.stopIntercepringRequest()
    }
    
    func test_getFromFurl_performsGETRequestWithURL() {
        let url = URL(string: "https://google.com")!
        
        let exp = expectation(description: "wait for the request")
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            
            exp.fulfill()
        }
        
        URLSessionHTTPClient().get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "https://google.com")!
        let error = NSError(domain: "any error", code: 1, userInfo: [:])
        URLProtocolStub.stub(data: nil, response: nil,  error: error)
        
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
    }
    
    // MARK: - HElpers
    
    private class URLProtocolStub: URLProtocol {
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?

        
        static func stub(data: Data?, response: URLResponse?, error: Error? = nil) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        
        static func startIntercepringRequest() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopIntercepringRequest() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }
        
        override func startLoading() {
            guard let stub = Self.stub else { return }
            
            if let data = stub.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = stub.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}
