/*===========================================================================
 ViewController.swift
 Mustang
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

class ViewController: NSViewController {
    
    @IBOutlet var usagePageArrayController: NSArrayController! = nil
    @IBOutlet var usageArrayController: NSArrayController! = nil
    
    @IBOutlet var usagePageTableView: NSTableView! = nil
    @IBOutlet var usageTableView: NSTableView! = nil
    
    private static let nameColumnIdentifier = NSUserInterfaceItemIdentifier(rawValue: "name")

    var managedObjectContext: NSManagedObjectContext? {
        return self.representedObject as? NSManagedObjectContext
    }
    
    // MARK: - ViewController implementation
    
    /*==========================================================================*/
    @IBAction func doAddUsagePage( _ sender: AnyObject? ) {
        
        guard let managedObjectContext = self.managedObjectContext else {
            fatalError( "Failed to obtain managed object context" )
        }
        guard let nextUsagePageID = self.nextUsagePageID() else { return }
        
        var newUsagePage: NSManagedObject! = nil
        
        managedObjectContext.performAndWait { 
            newUsagePage = NSEntityDescription.insertNewObject( forEntityName: UsagePageEntity.entityName, into: managedObjectContext )
            newUsagePage.setValue( nextUsagePageID, forKey: UsagePageEntity.usagePageKey )
            newUsagePage.setValue( "New Usage Page \(nextUsagePageID)", forKey: UsagePageEntity.nameKey )
        }
        
        self.usagePageArrayController.addObject( newUsagePage )
        
        self.usagePageTableView.window?.makeFirstResponder( self.usagePageTableView )
        
        let selectedRow = self.usagePageArrayController.selectionIndex
        self.usagePageTableView.scrollRowToVisible( selectedRow )
        
        let columnIndex = self.usagePageTableView.column( withIdentifier: ViewController.nameColumnIdentifier )
        self.usagePageTableView.editColumn( columnIndex, row: selectedRow, with: nil, select: true )
    }
    
    /*==========================================================================*/
    @IBAction func doAddUsage( _ sender: AnyObject? ) {
        
        guard let managedObjectContext = self.managedObjectContext else {
            fatalError( "Failed to obtain managed object context" )
        }
        guard let nextUsageID = self.nextUsageID() else { return }
        
        var newUsage:NSManagedObject! = nil
        managedObjectContext.performAndWait { 
            newUsage = NSEntityDescription.insertNewObject( forEntityName: UsageEntity.entityName, into: managedObjectContext )
            newUsage.setValue( nextUsageID, forKey: UsageEntity.usageKey )
            newUsage.setValue( "New Usage \(nextUsageID)", forKey: UsageEntity.nameKey )
        }
        
        self.usageArrayController.addObject( newUsage )
        
        self.usageTableView.window?.makeFirstResponder( self.usageTableView )
        
        let selectedRow = self.usageArrayController.selectionIndex
        self.usageTableView.scrollRowToVisible( selectedRow )
        
        let columnIndex = self.usageTableView.column( withIdentifier: ViewController.nameColumnIdentifier )
        self.usageTableView.editColumn( columnIndex, row: selectedRow, with: nil, select: true )
    }
    
    /*==========================================================================*/
    @IBAction func doAddUsagePageOrUsage( _ sender: AnyObject? ) {
        
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
    fileprivate func nextUsagePageID() -> Int? {
        
        guard let managedObjectContext = self.managedObjectContext else {
            fatalError( "Failed to obtain managed object context" )
        }
        
        var nextUsagePageID = 1
        
        var localError: NSError? = nil
        
        managedObjectContext.performAndWait {
            
            let sortDescriptor = NSSortDescriptor( key: UsagePageEntity.usagePageKey, ascending: false )
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
            fetchRequest.entity = NSEntityDescription.entity( forEntityName: UsagePageEntity.entityName, in: managedObjectContext )
            fetchRequest.sortDescriptors = [ sortDescriptor ]
            fetchRequest.fetchLimit = 1
            
            do {
                let fetchResults = try managedObjectContext.fetch( fetchRequest )
                let lastUsagePageID = (fetchResults.last as AnyObject).value( forKey: UsagePageEntity.usagePageKey ) as? Int ?? 0
                
                nextUsagePageID = ( lastUsagePageID + 1 )
            }
            catch {
                localError = error as NSError?
            }
        }
        
        guard localError == nil else {
            Swift.print( localError! )
            return nil
        }
        
        return nextUsagePageID
    }
    
    /*==========================================================================*/
    fileprivate func nextUsageID()-> Int? {
        
        guard let managedObjectContext = self.managedObjectContext else {
            fatalError( "Failed to obtain managed object context" )
        }
        guard let selectedObjects = self.usagePageArrayController.selectedObjects else { return nil }
        guard selectedObjects.count == 1 else { return nil }
        
        var nextUsageID = 1
        
        var localError: NSError? = nil
        
        let selectedUsagePage = selectedObjects.last
        guard let usagePage = (selectedUsagePage as AnyObject).value( forKey: UsagePageEntity.usagePageKey ) as? Int else { return nextUsageID }
        
        let predicate = NSPredicate( format: "usagePage.usagePage == %ld", usagePage )
        let sortDescriptor = NSSortDescriptor( key: UsageEntity.usageKey, ascending: false )
        
        managedObjectContext.performAndWait {
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
            fetchRequest.entity = NSEntityDescription.entity( forEntityName: UsageEntity.entityName, in: managedObjectContext )
            fetchRequest.predicate = predicate
            fetchRequest.sortDescriptors = [ sortDescriptor ]
            fetchRequest.fetchLimit = 1
            
            do {
                let fetchResult = try managedObjectContext.fetch( fetchRequest )
                let lastUsageID = (fetchResult.last as AnyObject).value( forKey: UsageEntity.usageKey ) as? Int ?? 0
                
                nextUsageID = ( lastUsageID + 1 )
            }
            catch {
                localError = error as NSError
            }
        }
        
        guard localError == nil else {
            Swift.print( localError! )
            return nil
        }
        
        return nextUsageID
    }
}

