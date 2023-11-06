//
//  Copyright © 2023. Viesure. All rights reserved.
//

import Foundation

func anyNSError() -> NSError {
    NSError(domain: "any", code: 0)
}

func anyURL() -> URL {
    URL(string: "https://anyURL().com")!
}

func anyData() -> Data {
    Data("any".utf8)
}
