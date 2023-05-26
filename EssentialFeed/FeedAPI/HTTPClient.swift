//
//  Copyright © 2023. Viesure. All rights reserved.
//

import Foundation

public typealias HttpClientResult = Result<(Data, HTTPURLResponse), Error>

public protocol HTTPClient {
    
    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropiate threads, if needed
    func get(from url: URL, completion: @escaping (HttpClientResult) -> Void)
}
