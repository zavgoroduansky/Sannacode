//
//  MasterViewController.swift
//  Sannacode
//
//  Created by Завгородянський Олег on 2/24/18.
//  Copyright © 2018 Завгородянський Олег. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController {

    static let chunkSize = 20
    
    var detailViewController: DetailViewController? = nil
    var dataSource = [Crypto]()

    override func viewDidLoad() {
        super.viewDidLoad()

        loadObjects(start: 0)
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl!.addTarget(self, action: #selector(self.forceUpdateTable(_:)), for: .valueChanged)
        
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = dataSource[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        if dataSource.count > indexPath.row {
            configureCell(cell: cell, object: dataSource[indexPath.row])
            if indexPath.row == dataSource.count-1 {
                loadObjects(start: dataSource.count)
            }
        }

        return cell
    }

    // MARK: - Private methods
    
    func loadObjects(start from: Int) {
        RemoteManager().fetchCrypto(from: from, limit: MasterViewController.chunkSize) { (cryptoArray, errorString) in
            if errorString != "" {
                let alert = UIAlertController(title: "Error", message: errorString, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                self.dataSource += cryptoArray
                
                if from == 0 {
                    self.tableView.reloadData()
                } else {
                    var indexArray = [IndexPath]()
                    let lastIndex = self.dataSource.count-MasterViewController.chunkSize
                    for index in 0..<MasterViewController.chunkSize {
                        indexArray.append(IndexPath(row: lastIndex+index, section: 0))
                    }
                    self.tableView.beginUpdates()
                    self.tableView.insertRows(at: indexArray, with: .automatic)
                    self.tableView.endUpdates()
                }
            }
        }
    }
    
    func configureCell(cell: UITableViewCell, object: Crypto?) {
        guard let crypto = object else {
            return
        }
        cell.textLabel!.text = crypto.name
        cell.detailTextLabel?.text = crypto.price_usd
    }
    
    @objc func forceUpdateTable(_ sender: Any) {
        self.dataSource.removeAll()
        loadObjects(start: 0)
        tableView.refreshControl?.endRefreshing()
    }
}

