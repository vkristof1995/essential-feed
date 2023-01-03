//
//  Copyright © 2023. Viesure. All rights reserved.
//

import XCTest

class RemoteFeedLoader {
    
}

class HTTPClient {
    var requestedURL: URL?
}


class RemoteFeedLoaderTests: XCTestCase {

    func test_init() {
        let client = HTTPClient()
        _ = RemoteFeedLoader()
        
        XCTAssertNil(client.requestedURL)
    }
}
