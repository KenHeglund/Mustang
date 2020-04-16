/*===========================================================================
MustangDocument.swift
Mustang
Copyright (c) 2016 OrderedBytes. All rights reserved.
===========================================================================*/

import Cocoa

/*==========================================================================*/

class MustangDocument: NSPersistentDocument {
	
	/*==========================================================================*/
	override init() {
		
		super.init()
		
		_ = MustangDocument.classInitialization
		
		let persistentStoreCoordinator = self.managedObjectContext?.persistentStoreCoordinator
		let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
		
		self.managedObjectContext = managedObjectContext
	}
	
	
	// MARK: - NSDocument
	
	/*==========================================================================*/
	override class var autosavesInPlace: Bool {
		false
	}
	
	/*==========================================================================*/
	override func makeWindowControllers() {
		let storyboardName: NSStoryboard.Name = "Main"
		let storyboard = NSStoryboard(name: storyboardName, bundle: nil)
		let identifier: NSStoryboard.SceneIdentifier = "MustangDocument Window Controller"
		
		guard let windowController = storyboard.instantiateController(withIdentifier: identifier) as? NSWindowController else {
			fatalError("Failed to instantiate window controller")
		}
		
		self.addWindowController(windowController)
		
		windowController.contentViewController?.representedObject = self.managedObjectContext
	}
	
	/*==========================================================================*/
	override func willPresentError(_ originalError: Error) -> Error {
		
		let error = originalError as NSError
		
		if error.domain != NSCocoaErrorDomain {
			return error
		}
		
		if error.code < NSValidationErrorMinimum || error.code > NSValidationErrorMaximum {
			return error
		}
		
		let errorString: String
		
		if let detailedErrors = error.userInfo[NSDetailedErrorsKey] as? [NSError] {
			errorString = self.errorStringForErrors(detailedErrors)
		}
		else if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
			errorString = self.errorStringForErrors([underlyingError])
		}
		else {
			return error
		}
		
		var newUserInfo = error.userInfo
		newUserInfo[NSLocalizedDescriptionKey] = errorString
		
		return NSError(domain: error.domain, code: error.code, userInfo: newUserInfo)
	}
	
	
	// MARK: - NSPersistentDocument
	
	/*==========================================================================*/
	override func configurePersistentStoreCoordinator(for url: URL, ofType fileType: String, modelConfiguration configuration: String?, storeOptions: [String: Any]?) throws {
		
		let options = MustangDocument.sqliteOptions
		
		let persistentStoreCoordinator = self.managedObjectContext?.persistentStoreCoordinator
		try persistentStoreCoordinator?.addPersistentStore(ofType: fileType, configurationName: configuration, at: url, options: options)
	}
	
	/*==========================================================================*/
	override func write(to absoluteURL: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType, originalContentsURL absoluteOriginalContentsURL: URL?) throws {
		
		// Handle only the case where a SaveAs is being performed and an existing URL is present, defer to the superclass for everything else.
		
		guard saveOperation == .saveAsOperation else {
			return try super.write(to: absoluteURL, ofType: typeName, for: saveOperation, originalContentsURL: absoluteOriginalContentsURL)
		}
		guard let originalContentURL = absoluteOriginalContentsURL else {
			return try super.write(to: absoluteURL, ofType: typeName, for: saveOperation, originalContentsURL: absoluteOriginalContentsURL)
		}
		
		guard let managedObjectContext = self.managedObjectContext else {
			fatalError("failed to obtain managed object context")
		}
		guard let persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator else {
			fatalError("failed to load persistent store coordinator")
		}
		guard let originalPersistentStore = persistentStoreCoordinator.persistentStore(for: originalContentURL) else {
			fatalError("failed to retrieve persistent store")
		}
		
		let options = MustangDocument.sqliteOptions
		
		try persistentStoreCoordinator.migratePersistentStore(originalPersistentStore, to: absoluteURL, options: options, withType: typeName)
		
		do {
			try managedObjectContext.save()
		}
		catch {
			Swift.print(error)
		}
	}
	
	
	// MARK: - IBAction implementation
	
	/*==========================================================================*/
	@IBAction private func doImport(_ sender: AnyObject) {
		
		guard let window = self.windowForSheet else {
			return
		}
		
		let openPanel = NSOpenPanel()
		openPanel.canChooseDirectories = false
		openPanel.allowsMultipleSelection = false
		openPanel.allowedFileTypes = ["plist"]
		
		openPanel.beginSheetModal(for: window) { (result: NSApplication.ModalResponse) in
			
			guard result == .OK else {
				return
			}
			guard let url = openPanel.urls.first else {
				return
			}
			
			self.importFromURL(url)
		}
	}
	
	/*==========================================================================*/
	@IBAction private func doExport(_ sender: AnyObject) {
		
		guard let window = self.windowForSheet else {
			return
		}
		
		let savePanel = NSSavePanel()
		savePanel.canCreateDirectories = true
		savePanel.canSelectHiddenExtension = true
		savePanel.allowedFileTypes = [ "plist" ]
		
		savePanel.beginSheetModal(for: window) { (result: NSApplication.ModalResponse) in
			
			guard result == .OK else {
				return
			}
			guard let url = savePanel.url else {
				return
			}
			
			self.exportToURL(url)
		}
	}
	
	
	// MARK: - Private
	
	/*==========================================================================*/
	private static let classInitialization: Void = {
		
		let defaultUsagePageTableSortKey = "usagePage"
		let defaultUsageTableSortKey = "usage"
		let usagePageTableSortDescriptorKey = "UsagePageTableSortDescriptors"
		let usageTableSortDescriptorKey = "UsageTableSortDescriptors"
		
		let usagePageDescriptor = NSSortDescriptor(key: defaultUsagePageTableSortKey, ascending: true, selector: #selector(NSNumber.compare(_:)))
		let usagePageData = NSKeyedArchiver.archivedData(withRootObject: [usagePageDescriptor])
		
		let usageDescriptor = NSSortDescriptor(key: defaultUsageTableSortKey, ascending: true, selector: #selector(NSNumber.compare(_:)))
		let usageData = NSKeyedArchiver.archivedData(withRootObject: [usageDescriptor])
		
		let defaultDict = [
			usagePageTableSortDescriptorKey: usagePageData,
			usageTableSortDescriptorKey: usageData,
		]
		
		UserDefaults.standard.register(defaults: defaultDict)
	}()
	
	private static let collectionTypeNames = ["None", "Application", "NamedArray", "Logical", "Physical"]
	
	private static let sqliteOptions: [String: Any] = [
		
		// These allow automatic migration
		NSMigratePersistentStoresAutomaticallyOption: true,
		NSInferMappingModelAutomaticallyOption: true,
		
		// This avoids adding -shm and -wal files alongside the sqlite file.  Those files are associated with a journaling mode that is billed as having better performance.  If documents can be written to a bundle (such that they appear as a single item in the Finder to the user), then this option should probably be omitted and the default journaling mode used.
		NSSQLitePragmasOption: ["journal_mode": "DELETE"],
	]
	
	/*==========================================================================*/
	private func importFromURL(_ URL: Foundation.URL) {
		
		guard let managedObjectContext = self.managedObjectContext else {
			fatalError("failed to obtain managed object context")
		}
		
		guard let hidDictionary = NSDictionary(contentsOf: URL) else {
			Swift.print("\(URL) does not contain an archived dictionary")
			return
		}
		
		guard let usagePagesDict = hidDictionary[HIDManagerKey.usagePages] as? [String: [String: AnyObject]] else {
			Swift.print("Archived dictionary does not contain a '\(HIDManagerKey.usagePages)' value at its root")
			return
		}
		
		managedObjectContext.performAndWait {
			
			for (usagePageKey, usagePageDict) in usagePagesDict {
				
				let pageScanner = Scanner(string: usagePageKey)
				var usagePage: UInt32 = 0
				guard pageScanner.scanHexInt32(&usagePage) else {
					Swift.print("Usage page key '\(usagePageKey) does not contain a hex value")
					continue
				}
				
				guard let usagePageName = usagePageDict[HIDManagerKey.usagePageName] as? String else {
					Swift.print("Dictionary for usage page '\(usagePageKey) does not contain a '\(HIDManagerKey.usagePageName)' value")
					continue
				}
				
				let usageNameFormat = usagePageDict[HIDManagerKey.usageNameFormat] as? String
				
				let newUsagePage = NSEntityDescription.insertNewObject(forEntityName: Entity.UsagePage.entityName, into: managedObjectContext)
				newUsagePage.setValue(Int(usagePage), forKey: Entity.UsagePage.usagePageKey)
				newUsagePage.setValue(usagePageName, forKey: Entity.UsagePage.nameKey)
				newUsagePage.setValue(usageNameFormat, forKey: Entity.UsagePage.usageNameFormatKey)
				
				guard let usagesDict = usagePageDict[HIDManagerKey.usages] as? [String: [String: AnyObject]] else { continue }
				
				for (usageKey, usageDict) in usagesDict {
					
					let usageScanner = Scanner(string: usageKey)
					var usage: UInt32 = 0
					if usageScanner.scanHexInt32(&usage) == false { continue }
					
					guard let usageName = usageDict[HIDManagerKey.usageName] as? String else {
						Swift.print("Dictionary for usage '\(usagePageKey):\(usageKey) does not contain a '\(HIDManagerKey.usageName)' value")
						continue
					}
					
					let newUsage = NSEntityDescription.insertNewObject(forEntityName: Entity.Usage.entityName, into: managedObjectContext)
					newUsage.setValue(newUsagePage, forKey: Entity.Usage.usagePageKey)
					newUsage.setValue(Int(usage), forKey: Entity.Usage.usageKey)
					newUsage.setValue(usageName, forKey: Entity.Usage.nameKey)
					
					if let collectionType = usageDict[HIDManagerKey.collectionType] as? String {
						newUsage.setValue(MustangDocument.collectionTypeNames.firstIndex(of: collectionType), forKey: Entity.Usage.collectionTypeKey)
					}
				}
			}
		}
	}
	
	/*==========================================================================*/
	private func exportToURL(_ URL: Foundation.URL) {
		
		guard let managedObjectContext = self.managedObjectContext else {
			fatalError("failed to obtain managed object context")
		}
		
		var localError: NSError?
		
		let rootDictionary = NSMutableDictionary()
		let usagePagesDict = NSMutableDictionary()
		rootDictionary[HIDManagerKey.usagePages] = usagePagesDict
		
		managedObjectContext.performAndWait {
			
			let usagePageRequest = NSFetchRequest<NSFetchRequestResult>()
			usagePageRequest.entity = NSEntityDescription.entity(forEntityName: Entity.UsagePage.entityName, in: managedObjectContext)
			
			do {
				
				let usagePageResult = try managedObjectContext.fetch(usagePageRequest)
				
				for usagePageEntity in usagePageResult {
					
					guard let usagePage = (usagePageEntity as AnyObject).value(forKey: Entity.UsagePage.usagePageKey) as? Int else {
						fatalError("Failed to obtain usage page value")
					}
					
					let usagePageDict = NSMutableDictionary()
					let usagePageKey = String(format: "0x%04lX", usagePage)
					usagePagesDict[usagePageKey] = usagePageDict
					
					guard let usagePageName = (usagePageEntity as AnyObject).value(forKey: Entity.UsagePage.nameKey) as? String else {
						fatalError("Failed to obtain usage page name")
					}
					usagePageDict[HIDManagerKey.usagePageName] = usagePageName
					
					if let usageNameFormat = (usagePageEntity as AnyObject).value(forKey: Entity.UsagePage.usageNameFormatKey) {
						usagePageDict[HIDManagerKey.usageNameFormat] = usageNameFormat
					}
					
					let usagesDict = NSMutableDictionary()
					usagePageDict[HIDManagerKey.usages] = usagesDict
					
					guard let usageEntities = (usagePageEntity as AnyObject).value(forKey: Entity.UsagePage.usagesKey) as? NSSet else { continue }
					
					for usageEntity in usageEntities {
						
						guard let usage = (usageEntity as AnyObject).value(forKey: Entity.Usage.usageKey) as? Int else {
							fatalError("Failed to obtain usage value")
						}
						
						let usageDict = NSMutableDictionary()
						let usageKey = String(format: "0x%04lX", usage)
						usagesDict[usageKey] = usageDict
						
						let usageName = (usageEntity as AnyObject).value(forKey: Entity.Usage.nameKey)
						usageDict[HIDManagerKey.usageName] = usageName
						
						if let collectionType = (usageEntity as AnyObject).value(forKey: Entity.Usage.collectionTypeKey) as? Int {
							
							if collectionType > 0 {
								usageDict[HIDManagerKey.collectionType] = MustangDocument.collectionTypeNames[collectionType]
							}
						}
					}
				}
			}
			catch {
				localError = error as NSError
			}
		}
		
		if let error = localError {
			Swift.print(error)
			return
		}
		
		do {
			let rootData = try PropertyListSerialization.data(fromPropertyList: rootDictionary, format: .binary, options: 0)
			try rootData.write(to: URL, options: [.atomic])
		}
		catch {
			Swift.print(error)
		}
	}
	
	/*==========================================================================*/
	private func errorStringForErrors(_ errors: [NSError]) -> String {
		
		let maxDisplayErrorCount = 5
		var errorString = ""
		
		if errors.count > 1 {
			errorString = "There are \(errors.count) validation errors:"
		}
		
		for error in errors.prefix(maxDisplayErrorCount) {
			
			if let validationObject = error.userInfo[NSValidationObjectErrorKey] {
				if let usagePage = (validationObject as AnyObject).value(forKey: Entity.UsagePage.usagePageKey) as? Int {
					// Only a Entity.UsagePage has a usagePage property as an Int
					errorString += "\nUsage Page \(usagePage): "
				}
				else if let usage = (validationObject as AnyObject).value(forKey: Entity.Usage.usageKey) as? Int {
					// Only a Entity.Usage has a usage property as an Int
					errorString += "\nUsage \(usage): "
				}
			}
			
			errorString += error.localizedDescription
		}
		
		if errors.count > maxDisplayErrorCount {
			errorString += "\n\(errors.count - maxDisplayErrorCount) more errors…"
		}
		
		return errorString
	}
}
