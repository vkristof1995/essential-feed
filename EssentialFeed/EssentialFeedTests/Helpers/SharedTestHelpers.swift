//
//  Copyright © 2023. Viesure. All rights reserved.
//

import Foundation

func anyNSError() -> NSError {
    NSError(domain: "any", code: 0)
}

var anyURL: URL {
    URL(string: "https://anyURL.com")!
}

var anyData: Data {
    Data("any".utf8)
}
