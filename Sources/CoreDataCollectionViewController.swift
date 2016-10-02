//
// CoreDataCollectionViewController.swift
//
// Copyright (c) 2014-2016 Marko Tadić <tadija@me.com> http://tadija.net
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import CoreData
import UIKit

/**
    Same concept as `CoreDataTableViewController`, but modified for use with `UICollectionViewController`.

    This class mostly just copies the code from `NSFetchedResultsController` documentation page
    into a subclass of `UICollectionViewController`.

    Just subclass this and set the `fetchedResultsController`.
    The only `UICollectionViewDataSource` method you'll **HAVE** to implement is `collectionView:cellForItemAtIndexPath:`.
    And you can use the `NSFetchedResultsController` method `objectAtIndexPath:` to do it.

    Remember that once you create an `NSFetchedResultsController`, you **CANNOT** modify its properties.
    If you want new fetch parameters (predicate, sorting, etc.),
    create a **NEW** `NSFetchedResultsController` and set this class's `fetchedResultsController` property again.
*/
open class CoreDataCollectionViewController: UICollectionViewController, NSFetchedResultsControllerDelegate {
    
    /// The controller *(this class fetches nothing if this is not set)*.
    open var fetchedResultsController: NSFetchedResultsController<NSManagedObject>? {
        didSet {
            if let frc = fetchedResultsController {
                if frc != oldValue {
                    frc.delegate = self
                    do {
                        try performFetch()
                    } catch {
                        print(error)
                    }
                }
            } else {
                collectionView?.reloadData()
            }
        }
    }
    
    /**
        Causes the `fetchedResultsController` to refetch the data.
        You almost certainly never need to call this.
        The `NSFetchedResultsController` class observes the context
        (so if the objects in the context change, you do not need to call `performFetch`
        since the `NSFetchedResultsController` will notice and update the collection view automatically).
        This will also automatically be called if you change the `fetchedResultsController` property.
    */
    open func performFetch() throws {
        if let frc = fetchedResultsController {
            defer {
                collectionView?.reloadData()
            }
            do {
                try frc.performFetch()
            } catch {
                throw error
            }
        }
    }
    
    fileprivate var _suspendAutomaticTrackingOfChangesInManagedObjectContext: Bool = false
    /**
        Turn this on before making any changes in the managed object context that
        are a one-for-one result of the user manipulating cells directly in the collection view.
        Such changes cause the context to report them (after a brief delay),
        and normally our `fetchedResultsController` would then try to update the collection view,
        but that is unnecessary because the changes were made in the collection view already (by the user)
        so the `fetchedResultsController` has nothing to do and needs to ignore those reports.
        Turn this back off after the user has finished the change.
        Note that the effect of setting this to NO actually gets delayed slightly
        so as to ignore previously-posted, but not-yet-processed context-changed notifications,
        therefore it is fine to set this to YES at the beginning of, e.g., `collectionView:moveItemAtIndexPath:toIndexPath:`,
        and then set it back to NO at the end of your implementation of that method.
        It is not necessary (in fact, not desirable) to set this during row deletion or insertion
        (but definitely for cell moves).
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
    
    // MARK: NSFetchedResultsControllerDelegate Helpers
    
    fileprivate var sectionInserts = [Int]()
    fileprivate var sectionDeletes = [Int]()
    fileprivate var sectionUpdates = [Int]()
    
    fileprivate var objectInserts = [IndexPath]()
    fileprivate var objectDeletes = [IndexPath]()
    fileprivate var objectUpdates = [IndexPath]()
    fileprivate var objectMoves = [IndexPath]()
    fileprivate var objectReloads = Set<IndexPath>()
    
    fileprivate func updateSectionsAndObjects() {
        // sections
        if !self.sectionInserts.isEmpty {
            for sectionIndex in self.sectionInserts {
                self.collectionView?.insertSections(IndexSet(integer: sectionIndex))
            }
            self.sectionInserts.removeAll(keepingCapacity: true)
        }
        if !self.sectionDeletes.isEmpty {
            for sectionIndex in self.sectionDeletes {
                self.collectionView?.deleteSections(IndexSet(integer: sectionIndex))
            }
            self.sectionDeletes.removeAll(keepingCapacity: true)
        }
        if !self.sectionUpdates.isEmpty {
            for sectionIndex in self.sectionUpdates {
                self.collectionView?.reloadSections(IndexSet(integer: sectionIndex))
            }
            self.sectionUpdates.removeAll(keepingCapacity: true)
        }
        // objects
        if !self.objectInserts.isEmpty {
            self.collectionView?.insertItems(at: self.objectInserts)
            self.objectInserts.removeAll(keepingCapacity: true)
        }
        if !self.objectDeletes.isEmpty {
            self.collectionView?.deleteItems(at: self.objectDeletes)
            self.objectDeletes.removeAll(keepingCapacity: true)
        }
        if !self.objectUpdates.isEmpty {
            self.collectionView?.reloadItems(at: self.objectUpdates)
            self.objectUpdates.removeAll(keepingCapacity: true)
        }
        if !self.objectMoves.isEmpty {
            let moveOperations = objectMoves.count / 2
            var index = 0
            for _ in 0 ..< moveOperations {
                self.collectionView?.moveItem(at: self.objectMoves[index], to: self.objectMoves[index + 1])
                index = index + 2
            }
            self.objectMoves.removeAll(keepingCapacity: true)
        }
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    
    /**
        Notifies the receiver of the addition or removal of a section.

        :param: controller The fetched results controller that sent the message.
        :param: sectionInfo The section that changed.
        :param: sectionIndex The index of the changed section.
        :param: type The type of change (insert or delete).
    */
    open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            sectionInserts.append(sectionIndex)
        case .delete:
            sectionDeletes.append(sectionIndex)
        case .update:
            sectionUpdates.append(sectionIndex)
        default:
            break
        }
    }
    
    /**
        Notifies the receiver that a fetched object has been changed due to an add, remove, move, or update.

        :param: controller The fetched results controller that sent the message.
        :param: anObject The object in controller’s fetched results that changed.
        :param: indexPath The index path of the changed object (this value is nil for insertions).
        :param: type The type of change.
        :param: newIndexPath The destination path for the object for insertions or moves (this value is nil for a deletion).
    */
    open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            objectInserts.append(newIndexPath!)
        case .delete:
            objectDeletes.append(indexPath!)
        case .update:
            objectUpdates.append(indexPath!)
        case .move:
            objectMoves.append(indexPath!)
            objectMoves.append(newIndexPath!)
            objectReloads.insert(indexPath!)
            objectReloads.insert(newIndexPath!)
        }
    }
    
    /**
        Notifies the receiver that the fetched results controller has completed processing of one or more changes due to an add, remove, move, or update.

        :param: controller The fetched results controller that sent the message.
    */
    open func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if !suspendAutomaticTrackingOfChangesInManagedObjectContext {
            // do batch updates on collection view
            collectionView?.performBatchUpdates({ () -> Void in
                self.updateSectionsAndObjects()
                }, completion: { (finished) -> Void in
                    // reload moved items when finished
                    if self.objectReloads.count > 0 {
                        self.collectionView?.reloadItems(at: Array(self.objectReloads))
                        self.objectReloads.removeAll()
                    }
            })
        }
    }
    
    // MARK: UICollectionViewDataSource
    
    /**
        Asks the data source for the number of sections in the collection view.

        :param: collectionView An object representing the collection view requesting this information.

        :returns: The number of sections in collectionView.
    */
    override open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController?.sections?.count ?? 1
    }
    
    /**
        Asks the data source for the number of items in the specified section. (required)

        :param: collectionView An object representing the collection view requesting this information.
        :param: section An index number identifying a section in collectionView.

        :returns: The number of rows in section.
    */
    override open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let superNumberOfItems = super.collectionView(collectionView, numberOfItemsInSection: section)
        return (fetchedResultsController?.sections?[section])?.numberOfObjects ?? superNumberOfItems
    }
    
}
