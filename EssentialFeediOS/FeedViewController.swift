//
//  Copyright © 2023 Viesure. All rights reserved.
//

import UIKit
import EssentialFeed

final public class FeedViewController: UITableViewController {
    private var loader: FeedLoader?
    
    convenience public init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }
    
    override public  func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        load()
    }
    
    override public func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        refreshControl?.beginRefreshing()
    }
    
    @objc private func load() {
        loader?.load { [weak self] _ in
            self?.refreshControl?.endRefreshing()
        }
    }
}
