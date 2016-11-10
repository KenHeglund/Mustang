/*===========================================================================
 HIDSpecification.swift
 Mustang
 Copyright (c) 2015 OrderedBytes. All rights reserved.
===========================================================================*/

import AppKit

/*==========================================================================*/

private let UsageNameFormatKey = "usageNameFormat"
private let UsageNameKey = "name"

private let UsagePlaceholder = "[[USAGE]]"

private let UsageEntityName = "UsageEntity"
private let UsagePageEntityName = "UsagePageEntity"

private let ModelFileName = "MustangDocument"
private let DataFileName = "HIDUsageTableDB"

/*==========================================================================*/

open class HIDSpecification: NSObject {
    
    fileprivate static let managedObjectContext: NSManagedObjectContext? = {
        
        let bundle = Bundle( for: HIDSpecification.self )
        
        guard let dataModelURL = bundle.url( forResource: ModelFileName, withExtension: "momd" ) else {
            Swift.print( "HIDSpecification framework failed to locate data model \"\(ModelFileName)\"" )
            return nil
        }
        guard let managedObjectModel = NSManagedObjectModel( contentsOf: dataModelURL ) else {
            Swift.print( "HIDSpecification framework failed to load data model \"\(dataModelURL)\"" )
            return nil
        }
        
        let persistentStoreCoordinator = NSPersistentStoreCoordinator( managedObjectModel: managedObjectModel )
        
        guard let databaseURL = bundle.url( forResource: DataFileName, withExtension: "sqlite" ) else {
            Swift.print( "HIDSpecification framework failed to locate data store \"\(DataFileName)\"" )
            return nil
        }
        
        do {
            let options = [ NSReadOnlyPersistentStoreOption : true ]
            try persistentStoreCoordinator.addPersistentStore( ofType: NSSQLiteStoreType, configurationName: nil, at: databaseURL, options: options )
        }
        catch {
            Swift.print( error )
            return nil
        }
        
        let concurrencyType = NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType
        let managedObjectContext = NSManagedObjectContext( concurrencyType: concurrencyType )
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        return managedObjectContext
    }()
    
    // MARK: Private methods
    
    /*==========================================================================*/
    fileprivate static func propertyForUsagePage( _ usagePage: Int, usage: Int?, key: String ) -> AnyObject? {
        
        guard let managedObjectContext = HIDSpecification.managedObjectContext else { return nil }
        
        var propertyValue: AnyObject? = nil
        
        let predicate: NSPredicate
        let entityName: String
        
        if let usage = usage {
            predicate = NSPredicate( format: "usage = %ld && usagePage.usagePage = %ld", usage, usagePage )
            entityName = UsageEntityName
        }
        else {
            predicate = NSPredicate( format: "usagePage = %ld", usagePage )
            entityName = UsagePageEntityName
        }
        
        var localError: NSError? = nil
        
        managedObjectContext.performAndWait {
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
            fetchRequest.entity = NSEntityDescription.entity( forEntityName: entityName, in: managedObjectContext )
            fetchRequest.predicate = predicate
            fetchRequest.fetchLimit = 1
            
            do {
                
                let fetchResult = try managedObjectContext.fetch( fetchRequest )
                if let firstResult = fetchResult.first as? NSManagedObject {
                    propertyValue = firstResult.value( forKey: key ) as AnyObject?
                }
            }
            catch {
                localError = error as NSError
            }
        }
        
        guard localError == nil else {
            Swift.print( localError! )
            return nil
        }
        
        return propertyValue
    }
    
    /*==========================================================================*/
    fileprivate static func namePropertyForUsagePage( _ usagePage: Int, usage: Int? ) -> String? {
        
        if let standardName = HIDSpecification.propertyForUsagePage( usagePage, usage: usage, key: UsageNameKey ) as? String {
            return standardName
        }
        
        guard let usage = usage else { return nil }
        guard let nameFormat = HIDSpecification.propertyForUsagePage( usagePage, usage: nil, key: UsageNameFormatKey ) else { return nil }
        
        return ( nameFormat.replacingOccurrences( of: UsagePlaceholder, with: "\(usage)" ) )
    }

    // MARK: - Public methods
    
    /*==========================================================================*/
    open static func nameForUsagePage( _ usagePage: Int, usage: Int ) -> String? {
        return ( HIDSpecification.namePropertyForUsagePage( usagePage, usage: usage ) )
    }
    
    /*==========================================================================*/
    open static func nameForUsagePage( _ usagePage: Int ) -> String? {
        return ( HIDSpecification.namePropertyForUsagePage( usagePage, usage: nil ) )
    }
    
    /*==========================================================================*/
    open static func isStandardUsagePage( _ usagePage: Int, usage: Int ) -> Bool {
        
        guard usagePage != 0 && usage != 0 else {
            return false
        }
        
        if HIDSpecification.propertyForUsagePage( usagePage, usage: usage, key: UsageNameKey ) != nil {
            return true
        }
        
        if HIDSpecification.propertyForUsagePage( usagePage, usage: nil, key: UsageNameFormatKey ) != nil {
            return true
        }
        
        return false
    }
}
