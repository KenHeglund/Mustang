/*===========================================================================
 MustangDocument.swift
 Mustang
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

let UsagePageEntity_EntityName = "UsagePageEntity"
let UsagePageEntity_UsagePageKey = "usagePage"
let UsagePageEntity_NameKey = "name"
let UsagePageEntity_UsageNameFormatKey = "usageNameFormat"
let UsagePageEntity_UsagesKey = "usages"

let UsageEntity_EntityName = "UsageEntity"
let UsageEntity_UsageKey = "usage"
let UsageEntity_NameKey = "name"
let UsageEntity_UsagePageKey = "usagePage"
let UsageEntity_CollectionTypeKey = "collectionType"

private let HIDManagerUsagePagesKey = "UsagePages"
private let HIDManagerUsagePageNameKey = "PageName"
private let HIDManagerUsagesKey = "Usages"
private let HIDManagerUsageNameKey = "UsageName"
private let HIDManagerUsageNameFormatKey = "UsageNameFormat"
private let HIDManagerCollectionTypeKey = "Collection"

private let MustangDocument_DefaultUsagePageTableSortKey = "usagePage"
private let MustangDocument_DefaultUsageTableSortKey = "usage"
private let MustangDocument_UsagePageTableSortDescriptorKey = "UsagePageTableSortDescriptors"
private let MustangDocument_UsageTableSortDescriptorKey = "UsageTableSortDescriptors"

private let MustangDocument_CollectionTypeNames = [ "None", "Application", "NamedArray", "Logical", "Physical" ]

/*==========================================================================*/

class MustangDocument: NSPersistentDocument {
    
    private static let sqliteOptions = [
        
        // These allow automatic migration
        NSMigratePersistentStoresAutomaticallyOption : true,
        NSInferMappingModelAutomaticallyOption : true,
        
        // This avoids adding -shm and -wal files alongside the sqlite file.  Those files are associated with a journaling mode that is billed as having better performance.  If documents can be written to a bundle (such that they appear as a single item in the Finder to the user), then this option should probably be omitted and the default journaling mode used.
        NSSQLitePragmasOption : [ "journal_mode" : "DELETE" ],
    ]

    
    /*==========================================================================*/
    override init() {
        
        super.init()
        
        let persistentStoreCoordinator = self.managedObjectContext?.persistentStoreCoordinator
        let managedObjectContext = NSManagedObjectContext( concurrencyType: .MainQueueConcurrencyType )
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        self.managedObjectContext = managedObjectContext
    }
    
    
    // MARK: - NSObject overrides
    
    /*==========================================================================*/
    override class func initialize() {
        
        let usagePageDescriptor = NSSortDescriptor( key: MustangDocument_DefaultUsagePageTableSortKey, ascending: true, selector: #selector(NSNumber.compare(_:)) )
        let usagePageData = NSKeyedArchiver.archivedDataWithRootObject( [usagePageDescriptor] )
        
        let usageDescriptor = NSSortDescriptor( key: MustangDocument_DefaultUsageTableSortKey, ascending: true, selector: #selector(NSNumber.compare(_:)) )
        let usageData = NSKeyedArchiver.archivedDataWithRootObject( [usageDescriptor] )
        
        let defaultDict = [
            MustangDocument_UsagePageTableSortDescriptorKey : usagePageData,
            MustangDocument_UsageTableSortDescriptorKey : usageData,
        ]
        
        NSUserDefaults.standardUserDefaults().registerDefaults( defaultDict )
    }
    
    
    // MARK: - NSDocument overrides
    
    /*==========================================================================*/
    override class func autosavesInPlace() -> Bool {
        return false
    }
    
    /*==========================================================================*/
    override func makeWindowControllers() {
        
        let storyboard = NSStoryboard( name: "Main", bundle: nil )
        let windowController = storyboard.instantiateControllerWithIdentifier( "MustangDocument Window Controller" ) as! NSWindowController
        self.addWindowController( windowController )
        
        windowController.contentViewController?.representedObject = self.managedObjectContext
    }
    
    /*==========================================================================*/
    override func willPresentError( error: NSError ) -> NSError {
        
        if error.domain != NSCocoaErrorDomain {
            return error
        }
        
        if error.code < NSValidationErrorMinimum || error.code > NSValidationErrorMaximum {
            return error
        }
        
        let errorString: String
        
        if let detailedErrors = error.userInfo[NSDetailedErrorsKey] as? [NSError] {
            errorString = self.errorStringForErrors( detailedErrors )
        }
        else if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
            errorString = self.errorStringForErrors( [underlyingError] )
        }
        else {
            return error
        }
        
        var newUserInfo = error.userInfo
        newUserInfo[NSLocalizedDescriptionKey] = errorString
        
        return NSError( domain: error.domain, code: error.code, userInfo: newUserInfo )
    }
    
    
    // MARK: - NSPersistentDocument overrides
    
    /*==========================================================================*/
    override func configurePersistentStoreCoordinatorForURL( url: NSURL, ofType fileType: String, modelConfiguration configuration: String?, storeOptions: [String : AnyObject]? ) throws {
        
        let options = MustangDocument.sqliteOptions
        
        let persistentStoreCoordinator = self.managedObjectContext?.persistentStoreCoordinator
        try persistentStoreCoordinator?.addPersistentStoreWithType( fileType, configuration: configuration, URL: url, options: options )
    }
    
    /*==========================================================================*/
    override func writeToURL( absoluteURL: NSURL, ofType typeName: String, forSaveOperation saveOperation: NSSaveOperationType, originalContentsURL absoluteOriginalContentsURL: NSURL? ) throws {
        
        // Handle only the case where a SaveAs is being performed and an existing URL is present, defer to the superclass for everything else.
        
        guard saveOperation == NSSaveOperationType.SaveAsOperation else {
            return try super.writeToURL( absoluteURL, ofType: typeName, forSaveOperation: saveOperation, originalContentsURL: absoluteOriginalContentsURL )
        }
        guard let originalContentURL = absoluteOriginalContentsURL else {
            return try super.writeToURL( absoluteURL, ofType: typeName, forSaveOperation: saveOperation, originalContentsURL: absoluteOriginalContentsURL )
        }
        
        guard let managedObjectContext = self.managedObjectContext else {
            fatalError( "failed to obtain managed object context" )
        }
        guard let persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator else {
            fatalError( "failed to load persistent store coordinator" )
        }
        guard let originalPersistentStore = persistentStoreCoordinator.persistentStoreForURL( originalContentURL ) else {
            fatalError( "failed to retrieve persistent store" )
        }
        
        let options = MustangDocument.sqliteOptions
        
        try persistentStoreCoordinator.migratePersistentStore( originalPersistentStore, toURL: absoluteURL, options: options, withType: typeName )
        
        do {
            try managedObjectContext.save()
        }
        catch {
            print( error )
        }
    }

    
    // MARK: - IBAction implementation
    
    /*==========================================================================*/
    @IBAction func doImport( sender: AnyObject ) {
        
        guard let window = self.windowForSheet else { return }
        
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = [ "plist" ]
        
        openPanel.beginSheetModalForWindow( window ) { ( result: Int ) in
            
            guard result == NSFileHandlingPanelOKButton else { return }
            guard let url = openPanel.URLs.first else { return }
            
            self.importFromURL( url )
        }
    }
    
    /*==========================================================================*/
    @IBAction func doExport( sender: AnyObject ) {
        
        guard let window = self.windowForSheet else { return }
        
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.canSelectHiddenExtension = true
        savePanel.allowedFileTypes = [ "plist" ]
        
        savePanel.beginSheetModalForWindow( window ) { ( result: Int ) in
            
            guard result == NSFileHandlingPanelOKButton else { return }
            guard let url = savePanel.URL else { return }
            
            self.exportToURL( url )
        }
    }
    
    
    // MARK: - MustangDocument internal
    
    /*==========================================================================*/
    private func importFromURL( URL: NSURL ) {
        
        guard let managedObjectContext = self.managedObjectContext else {
            fatalError( "failed to obtain managed object context" )
        }
        
        guard let hidDictionary = NSDictionary( contentsOfURL: URL ) else {
            print( "\(URL) does not contain an archived dictionary" )
            return
        }
        
        guard let usagePagesDict = hidDictionary[HIDManagerUsagePagesKey] as? [String:[String:AnyObject]] else {
            print( "Archived dictionary does not contain a '\(HIDManagerUsagePagesKey)' value at its root" )
            return
        }
        
        managedObjectContext.performBlockAndWait { 
            
            for ( usagePageKey, usagePageDict ) in usagePagesDict {
                
                let pageScanner = NSScanner( string: usagePageKey )
                var usagePage: UInt32 = 0
                guard pageScanner.scanHexInt( &usagePage ) else {
                    print( "Usage page key '\(usagePageKey) does not contain a hex value" )
                    continue
                }
                
                guard let usagePageName = usagePageDict[HIDManagerUsagePageNameKey] as? String else {
                    print( "Dictionary for usage page '\(usagePageKey) does not contain a '\(HIDManagerUsagePageNameKey)' value" )
                    continue
                }
                
                let usageNameFormat = usagePageDict[HIDManagerUsageNameFormatKey] as? String
                
                let newUsagePage = NSEntityDescription.insertNewObjectForEntityForName( UsagePageEntity_EntityName, inManagedObjectContext: managedObjectContext )
                newUsagePage.setValue( Int(usagePage), forKey: UsagePageEntity_UsagePageKey )
                newUsagePage.setValue( usagePageName, forKey: UsagePageEntity_NameKey )
                newUsagePage.setValue( usageNameFormat, forKey: UsagePageEntity_UsageNameFormatKey )
                
                guard let usagesDict = usagePageDict[HIDManagerUsagesKey] as? [String:[String:AnyObject]] else { continue }
                
                for ( usageKey, usageDict ) in usagesDict {
                    
                    let usageScanner = NSScanner( string: usageKey )
                    var usage: UInt32 = 0
                    if usageScanner.scanHexInt( &usage ) == false { continue }
                    
                    guard let usageName = usageDict[HIDManagerUsageNameKey] as? String else {
                        print( "Dictionary for usage '\(usagePageKey):\(usageKey) does not contain a '\(HIDManagerUsageNameKey)' value" )
                        continue
                    }
                    
                    let newUsage = NSEntityDescription.insertNewObjectForEntityForName( UsageEntity_EntityName, inManagedObjectContext: managedObjectContext )
                    newUsage.setValue( newUsagePage, forKey: UsageEntity_UsagePageKey )
                    newUsage.setValue( Int(usage), forKey: UsageEntity_UsageKey )
                    newUsage.setValue( usageName, forKey: UsageEntity_NameKey )
                    
                    if let collectionType = usageDict[HIDManagerCollectionTypeKey] as? String {
                        newUsage.setValue( MustangDocument_CollectionTypeNames.indexOf( collectionType ), forKey: UsageEntity_CollectionTypeKey )
                    }
                }
            }
        }
    }
    
    /*==========================================================================*/
    private func exportToURL( URL: NSURL ) {
        
        guard let managedObjectContext = self.managedObjectContext else {
            fatalError( "failed to obtain managed object context" )
        }
        
        var localError: ErrorType? = nil
        
        let rootDictionary = NSMutableDictionary()
        let usagePagesDict = NSMutableDictionary()
        rootDictionary[HIDManagerUsagePagesKey] = usagePagesDict
        
        managedObjectContext.performBlockAndWait {
            
            let usagePageRequest = NSFetchRequest()
            usagePageRequest.entity = NSEntityDescription.entityForName( UsagePageEntity_EntityName, inManagedObjectContext: managedObjectContext )
            
            do {
                
                let usagePageResult = try managedObjectContext.executeFetchRequest( usagePageRequest )
                
                for usagePageEntity in usagePageResult  {
                    
                    let usagePage = usagePageEntity.valueForKey( UsagePageEntity_UsagePageKey ) as! Int
                    
                    let usagePageDict = NSMutableDictionary()
                    let usagePageKey = String( format: "0x%04lX", usagePage )
                    usagePagesDict[usagePageKey] = usagePageDict
                    
                    let usagePageName = usagePageEntity.valueForKey( UsagePageEntity_NameKey ) as! String
                    usagePageDict[HIDManagerUsagePageNameKey] = usagePageName
                    
                    if let usageNameFormat = usagePageEntity.valueForKey( UsagePageEntity_UsageNameFormatKey ) {
                        usagePageDict[HIDManagerUsageNameFormatKey] = usageNameFormat
                    }
                    
                    let usagesDict = NSMutableDictionary()
                    usagePageDict[HIDManagerUsagesKey] = usagesDict
                    
                    guard let usageEntities = usagePageEntity.valueForKey( UsagePageEntity_UsagesKey ) as? NSSet else { continue }
                    
                    for usageEntity in usageEntities {
                        
                        let usage = usageEntity.valueForKey( UsageEntity_UsageKey ) as! Int
                        
                        let usageDict = NSMutableDictionary()
                        let usageKey = String( format: "0x%04lX", usage )
                        usagesDict[usageKey] = usageDict
                        
                        let usageName = usageEntity.valueForKey( UsageEntity_NameKey )
                        usageDict[HIDManagerUsageNameKey] = usageName
                        
                        if let collectionType = usageEntity.valueForKey( UsageEntity_CollectionTypeKey ) as? Int {
                            
                            if collectionType > 0 {
                                usageDict[HIDManagerCollectionTypeKey] = MustangDocument_CollectionTypeNames[collectionType]
                            }
                        }
                    }
                }
                
            }
            catch {
                localError = error
            }
        }
        
        guard localError == nil else {
            print( localError )
            return
        }
        
        do {
            let rootData = try NSPropertyListSerialization.dataWithPropertyList( rootDictionary, format: .BinaryFormat_v1_0, options: 0 )
            rootData.writeToURL( URL, atomically: true )
        }
        catch {
            print( error )
        }
    }
    
    /*==========================================================================*/
    private func errorStringForErrors( errors: [NSError] ) -> String {
        
        let maxDisplayErrorCount = 5
        let totalErrorCount = errors.count
        let displayErrorCount = min( totalErrorCount, maxDisplayErrorCount )
        var errorString = ""
        
        if totalErrorCount > 1 {
            errorString = "There are \(totalErrorCount) validation errors:\n"
        }
        
        for error in errors[0..<displayErrorCount] {
            
            if let validationObject = error.userInfo[NSValidationObjectErrorKey] {
                if let usagePage = validationObject.valueForKey( UsagePageEntity_UsagePageKey ) as? Int {
                    // Only a UsagePageEntity has a usagePage property as an Int
                    errorString += "Usage Page \(usagePage): "
                }
                else if let usage = validationObject.valueForKey( UsageEntity_UsageKey ) as? Int {
                    // Only a UsageEntity has a usage property as an Int
                    errorString += "Usage \(usage): "
                }
            }
            
            errorString += error.localizedDescription
            errorString += "\n"
        }
        
        if totalErrorCount > displayErrorCount {
            errorString += "\(totalErrorCount - displayErrorCount) more errors..."
        }
        
        return errorString
    }
}
