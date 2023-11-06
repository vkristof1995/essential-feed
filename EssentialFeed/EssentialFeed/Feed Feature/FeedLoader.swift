//
//  Copyright © 2023. Viesure. All rights reserved.
//

import Foundation

public protocol FeedLoader {
    typealias Result = Swift.Result<[FeedImage], Error>
    func load(completion: @escaping (FeedLoader.Result) -> Void)
}
