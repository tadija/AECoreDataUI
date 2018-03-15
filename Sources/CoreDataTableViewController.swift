/**
 *  https://github.com/tadija/AECoreDataUI
 *  Copyright (c) Marko Tadić 2014-2018
 *  Licensed under the MIT license. See LICENSE file.
 */

import CoreData
import UIKit

/**
    Swift version of class originaly created for **Stanford CS193p Winter 2013**.

    This class mostly just copies the code from `NSFetchedResultsController` 
    documentation page into a subclass of `UITableViewController`.

    Just subclass it and set the `fetchedResultsController` property.
    The only `UITableViewDataSource` method you'll have to implement is `tableView:cellForRowAtIndexPath:`.
    And you can use the `NSFetchedResultsController` method `objectAtIndexPath:` to do it.

    Remember that once you create an `NSFetchedResultsController`, you cannot modify its properties.
    If you want new fetch parameters (predicate, sorting, etc.),
    create a new `NSFetchedResultsController` and set this class's `fetchedResultsController` property again.
*/
open class CoreDataTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    // MARK: - Properties
    
    /// The controller (this class fetches nothing if this is not set).
    open var fetchedResultsController: NSFetchedResultsController<NSManagedObject>? {
        didSet {
            if let frc = fetchedResultsController {
                if frc != oldValue {
                    frc.delegate = self
                    do {
                        try performFetch()
                    } catch {
                        debugPrint(error)
                    }
                }
            } else {
                tableView.reloadData()
            }
        }
    }
    
    /**
        Turn this on before making any changes in the managed object context that
        are a one-for-one result of the user manipulating rows directly in the table view.
        Such changes cause the context to report them (after a brief delay),
        and normally our `fetchedResultsController` would then try to update the table,
        but that is unnecessary because the changes were made in the table already (by the user)
        so the `fetchedResultsController` has nothing to do and needs to ignore those reports.
        Turn this back off after the user has finished the change.
        Note that the effect of setting this to NO actually gets delayed slightly
        so as to ignore previously-posted, but not-yet-processed context-changed notifications,
        therefore it is fine to set this to YES at the beginning of `tableView:moveRowAtIndexPath:toIndexPath:`,
        and then set it back to NO at the end of your implementation of that method.
        It is not necessary (in fact, not desirable) to set this during row deletion or insertion
        (but definitely for row moves).
    */
    open var suspendAutomaticTrackingOfChangesInManagedObjectContext: Bool {
        get {
            return _suspendAutomaticTrackingOfChangesInManagedObjectContext
        }
        set (newValue) {
            if newValue == true {
                _suspendAutomaticTrackingOfChangesInManagedObjectContext = true
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    self._suspendAutomaticTrackingOfChangesInManagedObjectContext = false
                }
            }
        }
    }
    
    fileprivate var _suspendAutomaticTrackingOfChangesInManagedObjectContext: Bool = false
    fileprivate var beganUpdates: Bool = false
    
    // MARK: - API
    
    /**
        Causes the `fetchedResultsController` to refetch the data.
        You almost certainly never need to call this directly.
        The `NSFetchedResultsController` class observes the context,
        so if the objects in the context change, you do not need to call `performFetch`
        since the `NSFetchedResultsController` will notice and update the table automatically.
        This will also automatically be called if you change the `fetchedResultsController` property.
    */
    open func performFetch() throws {
        guard let frc = fetchedResultsController else { return }
        
        defer {
            tableView.reloadData()
        }
        
        do {
            try frc.performFetch()
        } catch {
            throw error
        }
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    open func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if !suspendAutomaticTrackingOfChangesInManagedObjectContext {
            tableView.beginUpdates()
            beganUpdates = true
        }
    }
    
    open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                         didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int,
                         for type: NSFetchedResultsChangeType) {
        
        if !suspendAutomaticTrackingOfChangesInManagedObjectContext {
            let sectionIndex = IndexSet(integer: sectionIndex)
            switch type {
            case .insert:
                tableView.insertSections(sectionIndex, with: .fade)
            case .delete:
                tableView.deleteSections(sectionIndex, with: .fade)
            default:
                return
            }
        }
    }
    
    open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                         didChange anObject: Any, at indexPath: IndexPath?,
                         for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if !suspendAutomaticTrackingOfChangesInManagedObjectContext {
            switch type {
            case .insert:
                guard let nip = newIndexPath else { break }
                if indexPath == nil { /// - Note: Bug fix for iOS 8.4, `indexPath` must be nil for `.insert`.
                    tableView.insertRows(at: [nip], with: .automatic)
                }
            case .delete:
                guard let ip = indexPath else { break }
                tableView.deleteRows(at: [ip], with: .automatic)
            case .update:
                if let ip = indexPath, let nip = newIndexPath {
                    if ip == nip {
                        tableView.reloadRows(at: [ip], with: .none)
                    } else {
                        /// - Note: Bug fix for iOS 10 (`.update` instead of `.move` -> `indexPath != newIndexPath`)
                        tableView.deleteRows(at: [ip], with: .automatic)
                        tableView.insertRows(at: [nip], with: .automatic)
                    }
                } else {
                    tableView.reloadRows(at: [indexPath!], with: .none)
                }
            case .move:
                guard
                    let ip = indexPath,
                    let nip = newIndexPath,
                    ip != nip /// - Note: Bug fix for iOS 9
                    else { break }
                /// - Note: The real `.move` logic is replaced with delete/insert to avoid crashes on iOS 8/9/10.
                tableView.deleteRows(at: [ip], with: .automatic)
                tableView.insertRows(at: [nip], with: .automatic)
            }
        }
    }
    
    open func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if beganUpdates {
            tableView.endUpdates()
            beganUpdates = false
        }
    }
    
    // MARK: - UITableViewDataSource
    
    open override func numberOfSections(in tableView: UITableView) -> Int {
        let superNumberOfSections = super.numberOfSections(in: tableView)
        guard let frc = fetchedResultsController else { return superNumberOfSections }
        return frc.sections?.count ?? superNumberOfSections
    }
    
    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let superNumberOfRows = super.tableView(tableView, numberOfRowsInSection: section)
        guard let frc = fetchedResultsController else { return superNumberOfRows }
        return (frc.sections?[section])?.numberOfObjects ?? superNumberOfRows
    }
    
    open override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let superTitleForHeader = super.tableView(tableView, titleForHeaderInSection: section)
        guard let frc = fetchedResultsController else { return superTitleForHeader }
        return (frc.sections?[section])?.name ?? superTitleForHeader
    }
    
    open override func tableView(_ tableView: UITableView,
                                 sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        guard let frc = fetchedResultsController else { return 0 }
        return frc.section(forSectionIndexTitle: title, at: index)
    }
    
    open override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return fetchedResultsController?.sectionIndexTitles
    }
    
}
