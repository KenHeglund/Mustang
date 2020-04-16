/*===========================================================================
HIDSpecification.swift
Mustang
Copyright (c) 2015 OrderedBytes. All rights reserved.
===========================================================================*/

import AppKit

/*==========================================================================*/

public class HIDSpecification: NSObject {
	
	private static let usageNameFormatKey = "usageNameFormat"
	private static let usageNameKey = "name"
	
	private static let usagePlaceholder = "[[USAGE]]"
	
	private static let usageEntityName = "UsageEntity"
	private static let usagePageEntityName = "UsagePageEntity"
	
	private static let modelFileName = "MustangDocument"
	private static let dataFileName = "HIDUsageTableDB"
	
	private static let managedObjectContext: NSManagedObjectContext? = {
		
		let bundle = Bundle(for: HIDSpecification.self)
		
		guard let dataModelURL = bundle.url(forResource: HIDSpecification.modelFileName, withExtension: "momd") else {
			Swift.print("HIDSpecification framework failed to locate data model \"\(HIDSpecification.modelFileName)\"")
			return nil
		}
		guard let managedObjectModel = NSManagedObjectModel(contentsOf: dataModelURL) else {
			Swift.print("HIDSpecification framework failed to load data model \"\(dataModelURL)\"")
			return nil
		}
		
		let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
		
		guard let databaseURL = bundle.url(forResource: HIDSpecification.dataFileName, withExtension: "sqlite") else {
			Swift.print("HIDSpecification framework failed to locate data store \"\(HIDSpecification.dataFileName)\"")
			return nil
		}
		
		do {
			let options = [NSReadOnlyPersistentStoreOption: true]
			try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: databaseURL, options: options)
		}
		catch {
			Swift.print(error)
			return nil
		}
		
		let concurrencyType = NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType
		let managedObjectContext = NSManagedObjectContext(concurrencyType: concurrencyType)
		managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
		
		return managedObjectContext
	}()
	
	
	// MARK: - Private
	
	/*==========================================================================*/
	private static func propertyForUsagePage(_ usagePage: Int, usage: Int?, key: String) -> AnyObject? {
		
		guard let managedObjectContext = HIDSpecification.managedObjectContext else {
			return nil
		}
		
		var propertyValue: AnyObject?
		
		let predicate: NSPredicate
		let entityName: String
		
		if let usage = usage {
			predicate = NSPredicate(format: "usage = %ld && usagePage.usagePage = %ld", usage, usagePage)
			entityName = HIDSpecification.usageEntityName
		}
		else {
			predicate = NSPredicate(format: "usagePage = %ld", usagePage)
			entityName = HIDSpecification.usagePageEntityName
		}
		
		var localError: NSError?
		
		managedObjectContext.performAndWait {
			
			let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
			fetchRequest.entity = NSEntityDescription.entity(forEntityName: entityName, in: managedObjectContext)
			fetchRequest.predicate = predicate
			fetchRequest.fetchLimit = 1
			
			do {
				
				let fetchResult = try managedObjectContext.fetch(fetchRequest)
				if let firstResult = fetchResult.first as? NSManagedObject {
					propertyValue = firstResult.value(forKey: key) as AnyObject?
				}
			}
			catch {
				localError = error as NSError
			}
		}
		
		if let error = localError {
			Swift.print(error)
			return nil
		}
		
		return propertyValue
	}
	
	/*==========================================================================*/
	private static func namePropertyForUsagePage(_ usagePage: Int, usage: Int?) -> String? {
		
		if let standardName = HIDSpecification.propertyForUsagePage(usagePage, usage: usage, key: HIDSpecification.usageNameKey) as? String {
			return standardName
		}
		
		guard let usage = usage else {
			return nil
		}
		guard let nameFormat = HIDSpecification.propertyForUsagePage(usagePage, usage: nil, key: HIDSpecification.usageNameFormatKey) else {
			return nil
		}
		
		return nameFormat.replacingOccurrences(of: HIDSpecification.usagePlaceholder, with: "\(usage)")
	}
	
	
	// MARK: - Public methods
	
	/*==========================================================================*/
	@objc public static func nameForUsagePage(_ usagePage: Int, usage: Int) -> String? {
		HIDSpecification.namePropertyForUsagePage(usagePage, usage: usage)
	}
	
	/*==========================================================================*/
	@objc public static func nameForUsagePage(_ usagePage: Int) -> String? {
		HIDSpecification.namePropertyForUsagePage(usagePage, usage: nil)
	}
	
	/*==========================================================================*/
	@objc public static func isStandardUsagePage(_ usagePage: Int, usage: Int) -> Bool {
		
		guard usagePage != 0, usage != 0 else {
			return false
		}
		
		if HIDSpecification.propertyForUsagePage(usagePage, usage: usage, key: HIDSpecification.usageNameKey) != nil {
			return true
		}
		
		if HIDSpecification.propertyForUsagePage(usagePage, usage: nil, key: HIDSpecification.usageNameFormatKey) != nil {
			return true
		}
		
		return false
	}
}
