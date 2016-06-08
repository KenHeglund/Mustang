/*===========================================================================
 ViewController.swift
 Mustang
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

private let ViewController_ColumnKey_Name = "name"

/*==========================================================================*/

class ViewController: NSViewController {
    
    @IBOutlet var usagePageArrayController: NSArrayController! = nil
    @IBOutlet var usageArrayController: NSArrayController! = nil
    
    @IBOutlet var usagePageTableView: NSTableView! = nil
    @IBOutlet var usageTableView: NSTableView! = nil
    
    var managedObjectContext: NSManagedObjectContext? {
        return self.representedObject as? NSManagedObjectContext
    }
    
    // MARK: - ViewController implementation
    
    /*==========================================================================*/
    @IBAction func doAddUsagePage( sender: AnyObject? ) {
        
        guard let managedObjectContext = self.managedObjectContext else {
            fatalError( "Failed to obtain managed object context" )
        }
        guard let nextUsagePageID = self.nextUsagePageID() else { return }
        
        var newUsagePage: NSManagedObject! = nil
        
        managedObjectContext.performBlockAndWait { 
            newUsagePage = NSEntityDescription.insertNewObjectForEntityForName( UsagePageEntity_EntityName, inManagedObjectContext: managedObjectContext )
            newUsagePage.setValue( nextUsagePageID, forKey: UsagePageEntity_UsagePageKey )
            newUsagePage.setValue( "New Usage Page \(nextUsagePageID)", forKey: UsagePageEntity_NameKey )
        }
        
        self.usagePageArrayController.addObject( newUsagePage )
        
        self.usagePageTableView.window?.makeFirstResponder( self.usagePageTableView )
        
        let selectedRow = self.usagePageArrayController.selectionIndex
        self.usagePageTableView.scrollRowToVisible( selectedRow )
        
        let columnIndex = self.usagePageTableView.columnWithIdentifier( ViewController_ColumnKey_Name )
        self.usagePageTableView.editColumn( columnIndex, row: selectedRow, withEvent: nil, select: true )
    }
    
    /*==========================================================================*/
    @IBAction func doAddUsage( sender: AnyObject? ) {
        
        guard let managedObjectContext = self.managedObjectContext else {
            fatalError( "Failed to obtain managed object context" )
        }
        guard let nextUsageID = self.nextUsageID() else { return }
        
        var newUsage:NSManagedObject! = nil
        managedObjectContext.performBlockAndWait { 
            newUsage = NSEntityDescription.insertNewObjectForEntityForName( UsageEntity_EntityName, inManagedObjectContext: managedObjectContext )
            newUsage.setValue( nextUsageID, forKey: UsageEntity_UsageKey )
            newUsage.setValue( "New Usage \(nextUsageID)", forKey: UsageEntity_NameKey )
        }
        
        self.usageArrayController.addObject( newUsage )
        
        self.usageTableView.window?.makeFirstResponder( self.usageTableView )
        
        let selectedRow = self.usageArrayController.selectionIndex
        self.usageTableView.scrollRowToVisible( selectedRow )
        
        let columnIndex = self.usageTableView.columnWithIdentifier( ViewController_ColumnKey_Name )
        self.usageTableView.editColumn( columnIndex, row: selectedRow, withEvent: nil, select: true )
    }
    
    /*==========================================================================*/
    @IBAction func doAddUsagePageOrUsage( sender: AnyObject? ) {
        
        guard let firstResponder = self.view.window?.firstResponder else { return }
        
        if firstResponder === self.usagePageTableView {
            self.doAddUsagePage( sender )
        }
        else if firstResponder === self.usageTableView {
            self.doAddUsage( sender )
        }
    }
    
    
    // MARK: - MustangDocument internal
    
    /*==========================================================================*/
    private func nextUsagePageID() -> Int? {
        
        guard let managedObjectContext = self.managedObjectContext else {
            fatalError( "Failed to obtain managed object context" )
        }
        
        var nextUsagePageID = 1
        
        var localError: ErrorType? = nil
        
        managedObjectContext.performBlockAndWait {
            
            let sortDescriptor = NSSortDescriptor( key: UsagePageEntity_UsagePageKey, ascending: false )
            
            let fetchRequest = NSFetchRequest()
            fetchRequest.entity = NSEntityDescription.entityForName( UsagePageEntity_EntityName, inManagedObjectContext: managedObjectContext )
            fetchRequest.sortDescriptors = [ sortDescriptor ]
            fetchRequest.fetchLimit = 1
            
            do {
                let fetchResults = try managedObjectContext.executeFetchRequest( fetchRequest )
                let lastUsagePageID = fetchResults.last?.valueForKey( UsagePageEntity_UsagePageKey ) as? Int ?? 0
                
                nextUsagePageID = ( lastUsagePageID + 1 )
            }
            catch {
                localError = error
            }
        }
        
        guard localError == nil else {
            print( localError )
            return nil
        }
        
        return nextUsagePageID
    }
    
    /*==========================================================================*/
    private func nextUsageID()-> Int? {
        
        guard let managedObjectContext = self.managedObjectContext else {
            fatalError( "Failed to obtain managed object context" )
        }
        guard let selectedObjects = self.usagePageArrayController.selectedObjects else { return nil }
        guard selectedObjects.count == 1 else { return nil }
        
        var nextUsageID = 1
        
        var localError: ErrorType? = nil
        
        let selectedUsagePage = selectedObjects.last
        guard let usagePage = selectedUsagePage?.valueForKey( UsagePageEntity_UsagePageKey ) as? Int else { return nextUsageID }
        
        let predicate = NSPredicate( format: "usagePage.usagePage == %ld", usagePage )
        let sortDescriptor = NSSortDescriptor( key: UsageEntity_UsageKey, ascending: false )
        
        managedObjectContext.performBlockAndWait {
            
            let fetchRequest = NSFetchRequest()
            fetchRequest.entity = NSEntityDescription.entityForName( UsageEntity_EntityName, inManagedObjectContext: managedObjectContext )
            fetchRequest.predicate = predicate
            fetchRequest.sortDescriptors = [ sortDescriptor ]
            fetchRequest.fetchLimit = 1
            
            do {
                let fetchResult = try managedObjectContext.executeFetchRequest( fetchRequest )
                let lastUsageID = fetchResult.last?.valueForKey( UsageEntity_UsageKey ) as? Int ?? 0
                
                nextUsageID = ( lastUsageID + 1 )
            }
            catch {
                localError = error
            }
        }
        
        guard localError == nil else {
            print( localError )
            return nil
        }
        
        return nextUsageID
    }
}

