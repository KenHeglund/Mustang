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

public class HIDSpecification: NSObject {
    
    private static let managedObjectContext: NSManagedObjectContext? = {
        
        let bundle = NSBundle( forClass: HIDSpecification.self )
        
        guard let dataModelURL = bundle.URLForResource( ModelFileName, withExtension: "momd" ) else {
            print( "HIDSpecification framework failed to locate data model \"\(ModelFileName)\"" )
            return nil
        }
        guard let managedObjectModel = NSManagedObjectModel( contentsOfURL: dataModelURL ) else {
            print( "HIDSpecification framework failed to load data model \"\(dataModelURL)\"" )
            return nil
        }
        
        let persistentStoreCoordinator = NSPersistentStoreCoordinator( managedObjectModel: managedObjectModel )
        
        guard let databaseURL = bundle.URLForResource( DataFileName, withExtension: "sqlite" ) else {
            print( "HIDSpecification framework failed to locate data store \"\(DataFileName)\"" )
            return nil
        }
        
        do {
            let options = [ NSReadOnlyPersistentStoreOption : true ]
            try persistentStoreCoordinator.addPersistentStoreWithType( NSSQLiteStoreType, configuration: nil, URL: databaseURL, options: options )
        }
        catch {
            print( error )
            return nil
        }
        
        let concurrencyType = NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType
        let managedObjectContext = NSManagedObjectContext( concurrencyType: concurrencyType )
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        return managedObjectContext
    }()
    
    // MARK: Private methods
    
    /*==========================================================================*/
    private static func propertyForUsagePage( usagePage: Int, usage: Int?, key: String ) -> AnyObject? {
        
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
        
        var localError: ErrorType? = nil
        
        managedObjectContext.performBlockAndWait {
            
            let fetchRequest = NSFetchRequest()
            fetchRequest.entity = NSEntityDescription.entityForName( entityName, inManagedObjectContext: managedObjectContext )
            fetchRequest.predicate = predicate
            fetchRequest.fetchLimit = 1
            
            do {
                propertyValue = try managedObjectContext.executeFetchRequest( fetchRequest ).first?.valueForKey( key )
            }
            catch {
                localError = error
            }
        }
        
        guard localError == nil else {
            print( localError )
            return nil
        }
        
        return propertyValue
    }
    
    /*==========================================================================*/
    private static func namePropertyForUsagePage( usagePage: Int, usage: Int? ) -> String? {
        
        if let standardName = HIDSpecification.propertyForUsagePage( usagePage, usage: usage, key: UsageNameKey ) as? String {
            return standardName
        }
        
        guard let usage = usage else { return nil }
        guard let nameFormat = HIDSpecification.propertyForUsagePage( usagePage, usage: nil, key: UsageNameFormatKey ) else { return nil }
        
        return ( nameFormat.stringByReplacingOccurrencesOfString( UsagePlaceholder, withString: "\(usage)" ) )
    }

    // MARK: - Public methods
    
    /*==========================================================================*/
    public static func nameForUsagePage( usagePage: Int, usage: Int ) -> String? {
        return ( HIDSpecification.namePropertyForUsagePage( usagePage, usage: usage ) )
    }
    
    /*==========================================================================*/
    public static func nameForUsagePage( usagePage: Int ) -> String? {
        return ( HIDSpecification.namePropertyForUsagePage( usagePage, usage: nil ) )
    }
    
    /*==========================================================================*/
    public static func isStandardUsagePage( usagePage: Int, usage: Int ) -> Bool {
        
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
