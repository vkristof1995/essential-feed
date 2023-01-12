//
//  Copyright © 2023. Viesure. All rights reserved.
//

import Foundation

public typealias LoadFeedResult = Result<[FeedItem], RemoteFeedLoader.Error>

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
