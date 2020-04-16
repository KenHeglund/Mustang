/*===========================================================================
ViewController.swift
Mustang
Copyright (c) 2016 OrderedBytes. All rights reserved.
===========================================================================*/

import Cocoa

/*==========================================================================*/

class ViewController: NSViewController {
	
	// MARK: - Private
	
	@IBOutlet private var usagePageArrayController: NSArrayController!
	@IBOutlet private var usageArrayController: NSArrayController!
	
	@IBOutlet private var usagePageTableView: NSTableView!
	@IBOutlet private var usageTableView: NSTableView!
	
	private static let nameColumnIdentifier = NSUserInterfaceItemIdentifier(rawValue: "name")
	
	var managedObjectContext: NSManagedObjectContext? {
		self.representedObject as? NSManagedObjectContext
	}
	
	/*==========================================================================*/
	@IBAction private  func doAddUsagePage(_ sender: AnyObject?) {
		
		guard let managedObjectContext = self.managedObjectContext else {
			fatalError("Failed to obtain managed object context")
		}
		guard let nextUsagePageID = self.nextUsagePageID() else {
			return
		}
		
		var newObject: NSManagedObject?
		
		managedObjectContext.performAndWait {
			newObject = NSEntityDescription.insertNewObject(forEntityName: Entity.UsagePage.entityName, into: managedObjectContext)
			newObject?.setValue(nextUsagePageID, forKey: Entity.UsagePage.usagePageKey)
			newObject?.setValue("New Usage Page \(nextUsagePageID)", forKey: Entity.UsagePage.nameKey)
		}
		
		guard let newUsagePage = newObject else {
			fatalError("Failed to create new Usage Page entity")
		}
		
		self.usagePageArrayController.addObject(newUsagePage)
		
		self.usagePageTableView.window?.makeFirstResponder(self.usagePageTableView)
		
		let selectedRow = self.usagePageArrayController.selectionIndex
		self.usagePageTableView.scrollRowToVisible(selectedRow)
		
		let columnIndex = self.usagePageTableView.column(withIdentifier: ViewController.nameColumnIdentifier)
		self.usagePageTableView.editColumn(columnIndex, row: selectedRow, with: nil, select: true)
	}
	
	/*==========================================================================*/
	@IBAction private func doAddUsage(_ sender: AnyObject?) {
		
		guard let managedObjectContext = self.managedObjectContext else {
			fatalError("Failed to obtain managed object context")
		}
		guard let nextUsageID = self.nextUsageID() else {
			return
		}
		
		var newObject: NSManagedObject?
		
		managedObjectContext.performAndWait {
			newObject = NSEntityDescription.insertNewObject(forEntityName: Entity.Usage.entityName, into: managedObjectContext)
			newObject?.setValue(nextUsageID, forKey: Entity.Usage.usageKey)
			newObject?.setValue("New Usage \(nextUsageID)", forKey: Entity.Usage.nameKey)
		}
		
		guard let newUsage = newObject else {
			fatalError("Failed to create new Usage entity")
		}
		
		self.usageArrayController.addObject(newUsage)
		
		self.usageTableView.window?.makeFirstResponder(self.usageTableView)
		
		let selectedRow = self.usageArrayController.selectionIndex
		self.usageTableView.scrollRowToVisible(selectedRow)
		
		let columnIndex = self.usageTableView.column(withIdentifier: ViewController.nameColumnIdentifier)
		self.usageTableView.editColumn(columnIndex, row: selectedRow, with: nil, select: true)
	}
	
	/*==========================================================================*/
	@IBAction private func doAddUsagePageOrUsage(_ sender: AnyObject?) {
		
		guard let firstResponder = self.view.window?.firstResponder else {
			return
		}
		
		if firstResponder === self.usagePageTableView {
			self.doAddUsagePage(sender)
		}
		else if firstResponder === self.usageTableView {
			self.doAddUsage(sender)
		}
	}
	
	
	// MARK: - MustangDocument internal
	
	/*==========================================================================*/
	private func nextUsagePageID() -> Int? {
		
		guard let managedObjectContext = self.managedObjectContext else {
			fatalError("Failed to obtain managed object context")
		}
		
		var nextUsagePageID = 1
		
		var localError: NSError?
		
		managedObjectContext.performAndWait {
			
			let sortDescriptor = NSSortDescriptor(key: Entity.UsagePage.usagePageKey, ascending: false)
			
			let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
			fetchRequest.entity = NSEntityDescription.entity(forEntityName: Entity.UsagePage.entityName, in: managedObjectContext)
			fetchRequest.sortDescriptors = [ sortDescriptor ]
			fetchRequest.fetchLimit = 1
			
			do {
				let fetchResults = try managedObjectContext.fetch(fetchRequest)
				let lastUsagePageID = (fetchResults.last as AnyObject).value(forKey: Entity.UsagePage.usagePageKey) as? Int ?? 0
				
				nextUsagePageID = (lastUsagePageID + 1)
			}
			catch {
				localError = error as NSError?
			}
		}
		
		if let error = localError {
			Swift.print(error)
			return nil
		}
		
		return nextUsagePageID
	}
	
	/*==========================================================================*/
	private func nextUsageID() -> Int? {
		
		guard let managedObjectContext = self.managedObjectContext else {
			fatalError("Failed to obtain managed object context")
		}
		guard let selectedObjects = self.usagePageArrayController.selectedObjects else {
			return nil
		}
		guard selectedObjects.count == 1 else {
			return nil
		}
		
		var nextUsageID = 1
		
		var localError: NSError?
		
		let selectedUsagePage = selectedObjects.last
		guard let usagePage = (selectedUsagePage as AnyObject).value(forKey: Entity.UsagePage.usagePageKey) as? Int else {
			return nextUsageID
		}
		
		let predicate = NSPredicate(format: "usagePage.usagePage == %ld", usagePage)
		let sortDescriptor = NSSortDescriptor(key: Entity.Usage.usageKey, ascending: false)
		
		managedObjectContext.performAndWait {
			
			let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
			fetchRequest.entity = NSEntityDescription.entity(forEntityName: Entity.Usage.entityName, in: managedObjectContext)
			fetchRequest.predicate = predicate
			fetchRequest.sortDescriptors = [ sortDescriptor ]
			fetchRequest.fetchLimit = 1
			
			do {
				let fetchResult = try managedObjectContext.fetch(fetchRequest)
				let lastUsageID = (fetchResult.last as AnyObject).value(forKey: Entity.Usage.usageKey) as? Int ?? 0
				
				nextUsageID = (lastUsageID + 1)
			}
			catch {
				localError = error as NSError
			}
		}
		
		if let error = localError {
			Swift.print(error)
			return nil
		}
		
		return nextUsageID
	}
}
