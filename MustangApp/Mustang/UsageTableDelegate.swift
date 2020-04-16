/*===========================================================================
UsageTableDelegate.swift
Mustang
Copyright (c) 2015 OrderedBytes. All rights reserved.
===========================================================================*/

import AppKit

/*==========================================================================*/

class UsageTableDelegate: NSObject {
	
	// MARK: - Private
	
	private var inhibitSelectionChange = false
	
	@IBOutlet private var usageArrayController: NSArrayController!
	
	/*==========================================================================*/
	@IBAction private func doChangeControl(_ sender: AnyObject) {
		
		guard let tableView = sender as? NSTableView else {
			return
		}
		guard let arrangedObjects = self.usageArrayController?.arrangedObjects as? NSArray else {
			return
		}
		
		let clickedColumn = tableView.clickedColumn
		guard let key = tableView.tableColumns[clickedColumn].sortDescriptorPrototype?.key else {
			return
		}
		
		let clickedRow = tableView.clickedRow
		let newValue = (arrangedObjects[clickedRow] as AnyObject).value(forKey: key)
		
		let selectedObjects = arrangedObjects.objects(at: tableView.selectedRowIndexes)
		for object in selectedObjects {
			(object as AnyObject).setValue(newValue, forKey: key)
		}
		
		self.inhibitSelectionChange = true
	}
}

/*==========================================================================*/
// MARK: -

extension UsageTableDelegate: NSTableViewDelegate {
	
	/*==========================================================================*/
	func selectionShouldChange(in tableView: NSTableView) -> Bool {
		
		// After changing a cell in an NSTableView, a delayed message is sent to the table to change its selection to just the row containing the edited cell.  The following code defeats that selection change and allows all rows that were selected at the time of the value change to remain selected thereafter.  A table's selection belongs to the user, not AppKit.
		
		if RunLoop.current.currentMode == nil {
			return true
		}
		
		if self.inhibitSelectionChange == false {
			return true
		}
		
		self.inhibitSelectionChange = false
		
		return false
	}
}
