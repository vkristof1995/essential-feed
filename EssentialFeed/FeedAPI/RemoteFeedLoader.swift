//
//  Copyright © 2023. Viesure. All rights reserved.
//

import Foundation

public typealias HttpClientResult = Result<(Data, HTTPURLResponse), Error>
public typealias RemoteFeedLoaderResult = Result<[FeedItem], RemoteFeedLoader.Error>

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HttpClientResult) -> Void)
}

public class RemoteFeedLoader {
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    private let url: URL
    private let client: HTTPClient
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (RemoteFeedLoaderResult) -> Void) {
        client.get(from: url) { result in
            switch result {
            case .success:
                completion(.failure(.invalidData))
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}
