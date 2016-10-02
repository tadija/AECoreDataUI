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

    This class mostly just copies the code from `NSFetchedResultsController` 
    documentation page into a subclass of `UICollectionViewController`.

    Just subclass this and set the `fetchedResultsController`.
    The only `UICollectionViewDataSource` method you'll have to implement is `collectionView:cellForItemAtIndexPath:`.
    And you can use the `NSFetchedResultsController` method `objectAtIndexPath:` to do it.

    Remember that once you create an `NSFetchedResultsController`, you cannot modify its properties.
    If you want new fetch parameters (predicate, sorting, etc.),
    create a new `NSFetchedResultsController` and set this class's `fetchedResultsController` property again.
*/
open class CoreDataCollectionViewController: UICollectionViewController, NSFetchedResultsControllerDelegate {
    
    // MARK: - Properties
    
    /// The controller *(this class fetches nothing if this is not set)*.
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
                collectionView?.reloadData()
            }
        }
    }
    
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
        therefore it is fine to set this to YES at the beginning of `collectionView:moveItemAtIndexPath:toIndexPath:`,
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
    
    fileprivate var _suspendAutomaticTrackingOfChangesInManagedObjectContext: Bool = false
    
    // MARK: - API
    
    /**
        Causes the `fetchedResultsController` to refetch the data.
        You almost certainly never need to call this.
        The `NSFetchedResultsController` class observes the context
        (so if the objects in the context change, you do not need to call `performFetch`
        since the `NSFetchedResultsController` will notice and update the collection view automatically).
        This will also automatically be called if you change the `fetchedResultsController` property.
    */
    open func performFetch() throws {
        guard let frc = fetchedResultsController else { return }
        
        defer {
            collectionView?.reloadData()
        }
        
        do {
            try frc.performFetch()
        } catch {
            throw error
        }
    }
    
    // MARK: - Helpers
    
    private func updateSectionsAndObjects() {
        updateSections()
        updateObjects()
    }
    
    private var sectionInserts = [Int]()
    private var sectionDeletes = [Int]()
    private var sectionUpdates = [Int]()
    
    private func updateSections() {
        if !sectionInserts.isEmpty {
            for sectionIndex in sectionInserts {
                collectionView?.insertSections(IndexSet(integer: sectionIndex))
            }
            sectionInserts.removeAll(keepingCapacity: true)
        }
        if !sectionDeletes.isEmpty {
            for sectionIndex in sectionDeletes {
                collectionView?.deleteSections(IndexSet(integer: sectionIndex))
            }
            sectionDeletes.removeAll(keepingCapacity: true)
        }
        if !sectionUpdates.isEmpty {
            for sectionIndex in sectionUpdates {
                collectionView?.reloadSections(IndexSet(integer: sectionIndex))
            }
            sectionUpdates.removeAll(keepingCapacity: true)
        }
    }
    
    private var objectInserts = [IndexPath]()
    private var objectDeletes = [IndexPath]()
    private var objectUpdates = [IndexPath]()
    private var objectMoves = [IndexPath]()
    private var objectReloads = Set<IndexPath>()
    
    private func updateObjects() {
        if !objectInserts.isEmpty {
            collectionView?.insertItems(at: objectInserts)
            objectInserts.removeAll(keepingCapacity: true)
        }
        if !objectDeletes.isEmpty {
            collectionView?.deleteItems(at: objectDeletes)
            objectDeletes.removeAll(keepingCapacity: true)
        }
        if !objectUpdates.isEmpty {
            collectionView?.reloadItems(at: objectUpdates)
            objectUpdates.removeAll(keepingCapacity: true)
        }
        if !objectMoves.isEmpty {
            let moveOperations = objectMoves.count / 2
            var index = 0
            for _ in 0 ..< moveOperations {
                collectionView?.moveItem(at: objectMoves[index], to: objectMoves[index + 1])
                index = index + 2
            }
            objectMoves.removeAll(keepingCapacity: true)
        }
    }
    
    private func reloadObjects() {
        if objectReloads.count > 0 {
            collectionView?.reloadItems(at: Array(objectReloads))
            objectReloads.removeAll()
        }
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                         didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int,
                         for type: NSFetchedResultsChangeType) {
        
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

    open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                         didChange anObject: Any, at indexPath: IndexPath?,
                         for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
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

    open func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if !suspendAutomaticTrackingOfChangesInManagedObjectContext {
            collectionView?.performBatchUpdates({ () -> Void in
                self.updateSectionsAndObjects()
            }, completion: { (finished) -> Void in
                self.reloadObjects()
            })
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    override open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController?.sections?.count ?? 1
    }

    override open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let superNumberOfItems = super.collectionView(collectionView, numberOfItemsInSection: section)
        guard let frc = fetchedResultsController else { return superNumberOfItems }
        return (frc.sections?[section])?.numberOfObjects ?? superNumberOfItems
    }
    
}
