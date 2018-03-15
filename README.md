[![Swift 4.0](https://img.shields.io/badge/Swift-4.0-orange.svg?style=flat)](https://swift.org)
[![Platforms iOS](https://img.shields.io/badge/Platforms-iOS-lightgray.svg?style=flat)](http://www.apple.com)
[![CocoaPods](https://img.shields.io/cocoapods/v/AECoreDataUI.svg?style=flat)](https://cocoapods.org/pods/AECoreDataUI)
[![Carthage](https://img.shields.io/badge/Carthage-compatible-brightgreen.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![License MIT](https://img.shields.io/badge/License-MIT-lightgrey.svg?style=flat)](https://github.com/tadija/AECoreDataUI/blob/master/LICENSE)

# AECoreDataUI
**Super awesome Core Data driven UI for iOS written in Swift**

> I made this for personal use, but feel free to use it or contribute.
> For more examples check out [Sources](Sources) and [Tests](Tests).

## Index
- [Intro](#intro)
- [Features](#features)
- [Usage](#usage)
    - [CoreDataTableViewController](#coredatatableviewcontroller)
    - [CoreDataCollectionViewController](#coredatacollectionviewcontroller)
- [Installation](#installation)
- [License](#license)

## Intro

**AECoreDataUI** was previously part of [AERecord](https://github.com/tadija/AERecord), 
so you may want to check that also.

When it comes to connecting data with the UI, nice approach is to use `NSFetchedResultsController`.
`CoreDataTableViewController` wrapper from [Stanford's CS193p](http://www.stanford.edu/class/cs193p/cgi-bin/drupal/downloads-2013-winter) is so great at it, that I've written it in Swift and made `CoreDataCollectionViewController` too in the same fashion.  

## Features
- Core Data driven **UITableViewController** (UI automatically reflects data in Core Data model)
- Core Data driven **UICollectionViewController** (UI automatically reflects data in Core Data model)

## Usage

You may check [this demo project](https://github.com/tadija/AECoreDataDemo) for example.

### CoreDataTableViewController
`CoreDataTableViewController` mostly just copies the code from `NSFetchedResultsController`
documentation page into a subclass of `UITableViewController`.

Just subclass it and set it's `fetchedResultsController` property.

After that you'll only have to implement `tableView(_:cellForRowAtIndexPath:)` 
and `fetchedResultsController` will take care of other required data source methods.
It will also update `UITableView` whenever the underlying data changes (insert, delete, update, move).

#### Example

```swift
import UIKit
import CoreData

class MyTableViewController: CoreDataTableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        refreshData()
    }

    func refreshData() {
        let sortDescriptors = [NSSortDescriptor(key: "timeStamp", ascending: true)]
        let request = Event.createFetchRequest(sortDescriptors: sortDescriptors)
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                              managedObjectContext: AERecord.Context.default,
                                                              sectionNameKeyPath: nil, cacheName: nil)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell
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
Same as with the `CoreDataTableViewController `, just with `CoreDataCollectionViewController `.

## Installation

- [Swift Package Manager](https://swift.org/package-manager/):

    ```
    .Package(url: "https://github.com/tadija/AECoreDataUI.git", majorVersion: 4)
    ```

- [Carthage](https://github.com/Carthage/Carthage):

    ```ogdl
    github "tadija/AECoreDataUI"
    ```

- [CocoaPods](http://cocoapods.org/):

    ```ruby
    pod 'AECoreDataUI'
    ```

## License
AECoreDataUI is released under the MIT license. See [LICENSE](LICENSE) for details.
