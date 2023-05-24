//
//  Copyright © 2023. Viesure. All rights reserved.
//

import Foundation
import EssentialFeed

func uniqueImage() -> FeedImage {
    FeedImage(id: UUID(), description: nil, location: nil, url: anyURL)
}

func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
    let models = [uniqueImage(), uniqueImage()]
    let local = models.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    
    return (models, local)
}

extension Date {
    
    func minusFeedCacheMaxAge() -> Date {
        adding(days: -7)
    }
    
    func adding(days: Int) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: Int) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .second, value: seconds, to: self)!
    }
}
