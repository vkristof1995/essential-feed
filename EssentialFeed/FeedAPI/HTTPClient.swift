//
//  Copyright © 2023. Viesure. All rights reserved.
//

import Foundation

public typealias HttpClientResult = Result<(Data, HTTPURLResponse), Error>

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HttpClientResult) -> Void)
}
