//
//  Copyright © 2023. Viesure. All rights reserved.
//

import Foundation

private final class FeedCachePolicy {
    private static  let calendar = Calendar(identifier: .gregorian)
    
    private init() { }
    private static var maxCacheAgeInDays: Int {
        7
    }

    static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        
        return date < maxCacheAge
    }
}

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}

extension LocalFeedLoader: FeedLoader {
    
    public typealias LoadResult = LoadFeedResult
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self else { return }
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .found(feed, timestamp) where FeedCachePolicy.validate(timestamp, against: currentDate()):
                completion(.success(feed.toModels()))
            case .found, .empty:
                completion(.success([]))
            }
        }
    }
}

extension LocalFeedLoader {
    
    public typealias SaveResult = Error?
    
    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self else { return }
            if let cachedDeletionError = error {
                completion(cachedDeletionError)
            } else {
                self.cache(feed, with: completion)
            }
        }
    }
    
    private func cache(_ feed: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
        store.insert(feed.toLocal(), timestamp: currentDate(), completion: { [weak self] error in
            guard self != nil else { return }
            completion(error)
        })
    }
}

extension LocalFeedLoader {
    
    public func validateCache() {
        store.retrieve { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure:
                self.store.deleteCachedFeed { _ in }
            case let .found(_, timestamp) where !FeedCachePolicy.validate(timestamp, against: currentDate()):
                self.store.deleteCachedFeed { _ in }
            case .empty, .found:
                break
            }
        }
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        self.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    }
}

private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        self.map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    }
}
