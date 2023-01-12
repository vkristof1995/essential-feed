//
//  Copyright © 2023. Viesure. All rights reserved.
//

import XCTest
import EssentialFeed

class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let url = URL(string: "http://google.com")!
        let (_, client) = makeSUT(url: url)
        
        XCTAssertNil(client.requestedURL)
    }
    
    func test_init_requestDataFromURL() {
        let url = URL(string: "http://google.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        
        XCTAssertNotNil(client.requestedURL)
    }
    
    func test_init_requestDataTwice() {
        let url = URL(string: "http://google.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(RemoteFeedLoader.Error.connectivity)) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        }
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        [199, 201, 300, 400, 500].enumerated().forEach { index, code in
            expect(sut, toCompleteWith: .failure(RemoteFeedLoader.Error.invalidData)) {
                let json = makeItemsJSON(items: [])
                client.complete(withStatusCode: code, data: json, at: index)
            }
        }
    }
    
    func test_deliversErrorOn200HTTPResponseWithInvalidJson() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .failure(RemoteFeedLoader.Error.invalidData)) {
            let invalidJSON = Data("asd".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        }
    }
    
    func test_deliversNoItemsWithEmptyJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .success([])) {
            let empty = makeItemsJSON(items: [])
            client.complete(withStatusCode: 200, data: empty)
        }
    }
    
    func test_deliversItemsWithValidJSON() {
        let (sut, client) = makeSUT()
        
        let item1 = makeItem(id: UUID(), description: nil, location: nil, imageURL: URL(string: "https://google.com")!)
        let item2 = makeItem(id: UUID(), description: "desc", location: "loc", imageURL: URL(string: "https://google2.com")!)
        
        expect(sut, toCompleteWith: .success([item1.model, item2.model])) {
            let jsonData = makeItemsJSON(items: [item1.json, item2.json])
            client.complete(withStatusCode: 200, data: jsonData)
        }
    }
    
    func test_load_doesNotDeliverResultAfterSUTHasBeenDeallocated() {
        let url = URL(string: "https://google.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        
        var capturedResults = [LoadFeedResult]()
        sut?.load { capturedResults.append($0) }
        
        sut = nil
        
        client.complete(withStatusCode: 200, data: makeItemsJSON(items: []))
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    // MARK: - Helper
    
    private func makeSUT(url: URL = URL(string: "http://google.com")!, file: StaticString = #filePath, line: UInt = #line) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        
        testForMemoryLeaks(sut, file: file, line: line)
        testForMemoryLeaks(client, file: file, line: line)
        
        return (sut, client)
    }
    
    private func testForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
    
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].compactMapValues { $0 }
        
        return (item, json)
    }
    
    private func makeItemsJSON(items: [[String: Any]]) -> Data {
        let itemsJSON = [
            "items" : items
        ]
        
        return try! JSONSerialization.data(withJSONObject: itemsJSON)
    }
    
    private func expect(
        _ sut: RemoteFeedLoader,
        toCompleteWith expectedResult: LoadFeedResult,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        
        let expectation = expectation(description: "wait for load")
        
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.success(let receivedItems), .success(let expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
            case (.failure(let receivedError as RemoteFeedLoader.Error), .failure(let expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult) got \(receivedResult) instead", file: file, line: line)
            }
            
            expectation.fulfill()
        }
        
        action()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURL: URL? {
            requestedURLs.last
        }
        
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        private var messages: [(url: URL, completion: (HttpClientResult) -> Void)] = []
        
        func get(from url: URL, completion: @escaping (HttpClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index], statusCode: code, httpVersion: nil, headerFields: nil)!
            
            messages[index].completion(.success((data, response)))
        }
    }
}
