# AECoreDataUI
**Super awesome Core Data driven UI for iOS written in Swift**

[![Language Swift 2.2](https://img.shields.io/badge/Language-Swift%202.2-orange.svg?style=flat)](https://swift.org)
[![Platforms iOS](https://img.shields.io/badge/Platforms-iOS-lightgray.svg?style=flat)](http://www.apple.com)
[![License MIT](https://img.shields.io/badge/License-MIT-lightgrey.svg?style=flat)](https://github.com/tadija/AECoreDataUI/blob/master/LICENSE)

[![CocoaPods Version](https://img.shields.io/cocoapods/v/AECoreDataUI.svg?style=flat)](https://cocoapods.org/pods/AECoreDataUI)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-brightgreen.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

**AECoreDataUI** was previously part of [AERecord](https://github.com/tadija/AERecord), so you may want to check that also.

>When it comes to connecting your data with the UI, the best approach is to use `NSFetchedResultsController`.
`CoreDataTableViewController` wrapper from [Stanford's CS193p](http://www.stanford.edu/class/cs193p/cgi-bin/drupal/downloads-2013-winter) is so great at it, that I've written it in Swift and made `CoreDataCollectionViewController` too in the same fashion.  

## Index
- [Features](#features)
- [Usage](#usage)
    - [CoreDataTableViewController](#coredatatableviewcontroller)
    - [CoreDataCollectionViewController](#coredatacollectionviewcontroller)
- [Requirements](#requirements)
- [Installation](#installation)
- [License](#license)

## Features
- Core Data driven **UITableViewController** (UI automatically reflects data in Core Data model)
- Core Data driven **UICollectionViewController** (UI automatically reflects data in Core Data model)

## Usage

You can also check demo project in [AERecord](https://github.com/tadija/AERecord).

### CoreDataTableViewController
`CoreDataTableViewController` mostly just copies the code from `NSFetchedResultsController`
documentation page into a subclass of `UITableViewController`.

Just subclass it and set it's `fetchedResultsController` property.

After that you'll only have to implement `tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell` and `fetchedResultsController` will take care of other required data source methods.
It will also update `UITableView` whenever the underlying data changes (insert, delete, update, move).

#### Example

```swift
import UIKit
import CoreData

class MyTableViewController: CoreDataTableViewController {

	override func viewDidLoad() {
	    super.viewDidLoad()
	    tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
	    refreshData()
	}

	func refreshData() {
	    let sortDescriptors = [NSSortDescriptor(key: "timeStamp", ascending: true)]
	    let request = Event.createFetchRequest(sortDescriptors: sortDescriptors)
	    fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: AERecord.defaultContext, sectionNameKeyPath: nil, cacheName: nil)
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
	    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
	    if let frc = fetchedResultsController {
	        if let object = frc.objectAtIndexPath(indexPath) as? Event {
	            cell.textLabel.text = object.timeStamp.description
	        }
	    }
	    return cell
	}

}
```

### CoreDataCollectionViewController
Same as with the tableView.

## Requirements
- Xcode 7.3+
- iOS 8.0+

## Installation

- Using [CocoaPods](http://cocoapods.org/):

    ```ruby
    pod 'AECoreDataUI'
    ```

- [Carthage](https://github.com/Carthage/Carthage):

    ```ogdl
    github "tadija/AECoreDataUI"
    ```

- Manually:

  Just drag **AECoreDataUI.swift** into your project and start using it.

## License
AECoreDataUI is released under the MIT license. See [LICENSE](LICENSE) for details.
