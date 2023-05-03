//
//  Copyright © 2023. Viesure. All rights reserved.
//

import Foundation

public protocol FeedLoader {
    func load(completion: @escaping (Result<[FeedImage], Error>) -> Void)
}
