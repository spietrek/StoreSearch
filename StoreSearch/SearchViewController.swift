//
//  SearchViewController.swift
//  StoreSearch
//
//  Created by Stephen Pietrek on 11/10/15.
//  Copyright © 2015 Stephen Pietrek. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    
    var searchResults = [SearchResult]()
    var hasSearched = false
    let baseSearchUrl = "https://itunes.apple.com/search?term=%@"
    let refreshControl = UIRefreshControl()
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    struct TableViewCellIdentifiers {
        static let searchResultCell = "SearchResultCell"
        static let nothingFoundCell = "NothingFoundCell"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
        tableView.rowHeight = 80
        
        var cellNib = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
        cellNib = UINib(nibName: TableViewCellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.nothingFoundCell)
        
        searchBar.becomeFirstResponder()
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: Selector("executeSearch"), forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
    }
    
    func executeSearch() {
        refreshControl.endRefreshing()
        if !searchBar.text!.isEmpty {
            searchBar.resignFirstResponder()
            hasSearched = true;
            searchResults = [SearchResult]()
            
            let url = urlWithSearchText(searchBar.text!)
            
            if let jsonString = performStoreRequestWithUrl(url) {
                if let dictionary = parseJSON(jsonString) {
                    print("Dictionary '\(dictionary)'")
                    parseDictionary(dictionary)
                    tableView.reloadData()
                    return
                }
            }
            showNetworkError()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func urlWithSearchText(searchText: String) -> NSURL {
        let escapedSearchText = searchText.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!
        
        let urlString = String(format: baseSearchUrl, escapedSearchText)
        let url = NSURL(string: urlString)
        return url!
    }
    
    func performStoreRequestWithUrl(url: NSURL) -> String? {
        do {
            return try String(contentsOfURL: url, encoding: NSUTF8StringEncoding)
        } catch {
            print("Download Error: \(error)")
            return nil
        }
    }
    
    func parseJSON(jsonString: String) -> [String: AnyObject]? {
        guard let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding) else {return nil}
        
        do {
            return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String: AnyObject]
        } catch {
            print("JSON Parse Error: \(error)")
            return nil
        }
    }
    
    func parseDictionary(dictionary: [String: AnyObject]) {
        guard let array = dictionary["results"] as? [AnyObject] else {
            print("Expected 'results' array")
            return
        }
        
        for resultDict in array {
            if let resultDict = resultDict as? [String: AnyObject] {
                if let wrapperType = resultDict["wrapperType"] as? String,
                    let kind = resultDict["kind"] as? String {
                        print("wrapperType: \(wrapperType), kind: \(kind)")
                }
            }
        }
    }
    
    func showNetworkError() {
        let alert = UIAlertController(title: "Whoops...",
            message: "There was an error reading from the iTunes store. Please try again.",
            preferredStyle: .Alert)
        
        let action = UIAlertAction(title: "OK", style:.Default, handler: nil)
        alert.addAction(action)
        
        presentViewController(alert, animated: true, completion: nil)
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        executeSearch()
    }
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
}

extension SearchViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !hasSearched {
            return 0
        } else if searchResults.count == 0 {
            return 1
        } else {
            return searchResults.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if searchResults.count == 0 {
            return tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.nothingFoundCell, forIndexPath:indexPath)
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.searchResultCell, forIndexPath:indexPath) as! SearchResultCell
            let searchResult = searchResults[indexPath.row]
            cell.nameLabel.text = searchResult.name
            cell.artistNameLabel.text = searchResult.artistName
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if searchResults.count == 0 {
            return nil
        } else {
            return indexPath
        }
    }
}

extension SearchViewController: UITableViewDelegate {
    
}

