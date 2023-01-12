//
//  Copyright © 2023. Viesure. All rights reserved.
//

import Foundation

public typealias RemoteFeedLoaderResult = Result<[FeedItem], RemoteFeedLoader.Error>

public class RemoteFeedLoader: FeedLoader {
    
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
    
    public func load(completion: @escaping (LoadFeedResult<RemoteFeedLoader.Error>) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case .success(let (data, response)):
                completion(FeedItemsMapper.map(data, from: response))
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}
