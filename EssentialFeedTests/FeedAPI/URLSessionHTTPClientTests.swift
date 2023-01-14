//
//  Copyright © 2023. Viesure. All rights reserved.
//

import XCTest
import EssentialFeed

protocol HTTPSession {
    func dataTask(with url: URL, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask
}

protocol HTTPSessionTask {
    func resume()
}

class URLSessionHTTPClient {
    private let session: HTTPSession
    
    init(session: HTTPSession) {
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
    
    func test_getFromUrl_resumesDataTaskWithURL() {
        let url = URL(string: "https://google.com")!
        let session = URLSessionSpy()
        let task = URLSessionDataTaskSpy()
        session.stub(url: url, task: task)
        
        let sut = URLSessionHTTPClient(session: session)
        
        sut.get(from: url) { _ in }
        
        XCTAssertEqual(task.resumeCallCount, 1)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "https://google.com")!
        let session = URLSessionSpy()
        let error = NSError(domain: "any error", code: 1)
        session.stub(url: url, error: error)
        
        let sut = URLSessionHTTPClient(session: session)
        
        let expectation = expectation(description: "wait for completion")
        sut.get(from: url) { result in
            switch result {
            case let .failure(resceivedError as NSError):
                XCTAssertEqual(resceivedError, error)
            default:
                XCTFail("expected failure with error \(error) got result instead")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    // MARK: - HElpers
    
    private class URLSessionSpy: HTTPSession {
        
        private struct Stub {
            let task: HTTPSessionTask
            let error: Error?
        }
        
        private var stubs = [URL: Stub]()

        
        func stub(url: URL, task: HTTPSessionTask = FakeURLSessionDataTask(), error: Error? = nil) {
            stubs[url] = Stub(task: task, error: error)
        }
        
        func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask {
            guard let stub = stubs[url] else {
                fatalError("Couldn't find stub for \(url)")
            }
            
            completionHandler(nil, nil, stub.error)
            return stub.task
        }
    }
    
    private class FakeURLSessionDataTask: HTTPSessionTask {
        func resume() {
            
        }
    }
    private class URLSessionDataTaskSpy: HTTPSessionTask {
        var resumeCallCount = 0
        
        func resume() {
            resumeCallCount += 1
        }
    }
}
