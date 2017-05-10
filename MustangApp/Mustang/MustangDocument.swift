/*===========================================================================
 MustangDocument.swift
 Mustang
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

struct UsagePageEntityKeys {
    static let entityName = "UsagePageEntity"
    static let usagePageKey = "usagePage"
    static let nameKey = "name"
    static let usageNameFormatKey = "usageNameFormat"
    static let usagesKey = "usages"
}

struct UsageEntityKeys {
    static let entityName = "UsageEntity"
    static let usageKey = "usage"
    static let nameKey = "name"
    static let usagePageKey = "usagePage"
    static let collectionTypeKey = "collectionType"
    static let doubtfulKey = "doubtful"
    static let spuriousKey = "spurious"
}

fileprivate struct HIDManagerKeys {
    static let usagePagesKey = "UsagePages"
    static let usagePageNameKey = "PageName"
    static let usagesKey = "Usages"
    static let usageNameKey = "UsageName"
    static let usageNameFormatKey = "UsageNameFormat"
    static let collectionTypeKey = "Collection"
    static let doubtfulKey = "Doubtful"
    static let spuriousKey = "Spurious"
}

/*==========================================================================*/
private let initializationTask: Void = {
    
    let defaultUsagePageTableSortKey = "usagePage"
    let defaultUsageTableSortKey = "usage"
    let usagePageTableSortDescriptorKey = "UsagePageTableSortDescriptors"
    let usageTableSortDescriptorKey = "UsageTableSortDescriptors"
    
    let usagePageDescriptor = NSSortDescriptor( key: defaultUsagePageTableSortKey, ascending: true, selector: #selector(NSNumber.compare(_:)) )
    let usagePageData = NSKeyedArchiver.archivedData( withRootObject: [usagePageDescriptor] )
    
    let usageDescriptor = NSSortDescriptor( key: defaultUsageTableSortKey, ascending: true, selector: #selector(NSNumber.compare(_:)) )
    let usageData = NSKeyedArchiver.archivedData( withRootObject: [usageDescriptor] )
    
    let defaultDict = [
        usagePageTableSortDescriptorKey : usagePageData,
        usageTableSortDescriptorKey : usageData,
    ]
    
    UserDefaults.standard.register( defaults: defaultDict )
}()

/*==========================================================================*/

class MustangDocument: NSPersistentDocument {
    
    private static let collectionTypeNames = [ "None", "Application", "NamedArray", "Logical", "Physical" ]
    
    fileprivate static let sqliteOptions = [
        
        // These allow automatic migration
        NSMigratePersistentStoresAutomaticallyOption : true,
        NSInferMappingModelAutomaticallyOption : true,
        
        // This avoids adding -shm and -wal files alongside the sqlite file.  Those files are associated with a journaling mode that is billed as having better performance.  If documents can be written to a bundle (such that they appear as a single item in the Finder to the user), then this option should probably be omitted and the default journaling mode used.
        NSSQLitePragmasOption : [ "journal_mode" : "DELETE" ],
    ] as [String : Any]

    
    /*==========================================================================*/
    override init() {
        
        super.init()
        
        initializationTask
        
        let persistentStoreCoordinator = self.managedObjectContext?.persistentStoreCoordinator
        let managedObjectContext = NSManagedObjectContext( concurrencyType: .mainQueueConcurrencyType )
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        self.managedObjectContext = managedObjectContext
    }
    
    
    // MARK: - NSDocument overrides
    
    /*==========================================================================*/
    override class func autosavesInPlace() -> Bool {
        return false
    }
    
    /*==========================================================================*/
    override func makeWindowControllers() {
        
        let storyboard = NSStoryboard( name: "Main", bundle: nil )
        let windowController = storyboard.instantiateController( withIdentifier: "MustangDocument Window Controller" ) as! NSWindowController
        self.addWindowController( windowController )
        
        windowController.contentViewController?.representedObject = self.managedObjectContext
    }
    
    /*==========================================================================*/
    override func willPresentError( _ originalError: Error ) -> Error {
        
        let error = originalError as NSError
        
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
    override func configurePersistentStoreCoordinator( for url: URL, ofType fileType: String, modelConfiguration configuration: String?, storeOptions: [String : Any]? ) throws {
        
        let options = MustangDocument.sqliteOptions
        
        let persistentStoreCoordinator = self.managedObjectContext?.persistentStoreCoordinator
        try persistentStoreCoordinator?.addPersistentStore( ofType: fileType, configurationName: configuration, at: url, options: options )
    }
    
    /*==========================================================================*/
    override func write( to absoluteURL: URL, ofType typeName: String, for saveOperation: NSSaveOperationType, originalContentsURL absoluteOriginalContentsURL: URL? ) throws {
        
        // Handle only the case where a SaveAs is being performed and an existing URL is present, defer to the superclass for everything else.
        
        guard saveOperation == NSSaveOperationType.saveAsOperation else {
            return try super.write( to: absoluteURL, ofType: typeName, for: saveOperation, originalContentsURL: absoluteOriginalContentsURL )
        }
        guard let originalContentURL = absoluteOriginalContentsURL else {
            return try super.write( to: absoluteURL, ofType: typeName, for: saveOperation, originalContentsURL: absoluteOriginalContentsURL )
        }
        
        guard let managedObjectContext = self.managedObjectContext else {
            fatalError( "failed to obtain managed object context" )
        }
        guard let persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator else {
            fatalError( "failed to load persistent store coordinator" )
        }
        guard let originalPersistentStore = persistentStoreCoordinator.persistentStore( for: originalContentURL ) else {
            fatalError( "failed to retrieve persistent store" )
        }
        
        let options = MustangDocument.sqliteOptions
        
        try persistentStoreCoordinator.migratePersistentStore( originalPersistentStore, to: absoluteURL, options: options, withType: typeName )
        
        do {
            try managedObjectContext.save()
        }
        catch {
            Swift.print( error )
        }
    }

    
    // MARK: - IBAction implementation
    
    /*==========================================================================*/
    @IBAction func doImport( _ sender: AnyObject ) {
        
        guard let window = self.windowForSheet else { return }
        
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = [ "plist" ]
        
        openPanel.beginSheetModal( for: window ) { ( result: Int ) in
            
            guard result == NSFileHandlingPanelOKButton else { return }
            guard let url = openPanel.urls.first else { return }
            
            self.importFromURL( url )
        }
    }
    
    /*==========================================================================*/
    @IBAction func doExport( _ sender: AnyObject ) {
        
        guard let window = self.windowForSheet else { return }
        
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.canSelectHiddenExtension = true
        savePanel.allowedFileTypes = [ "plist" ]
        
        savePanel.beginSheetModal( for: window ) { ( result: Int ) in
            
            guard result == NSFileHandlingPanelOKButton else { return }
            guard let url = savePanel.url else { return }
            
            self.exportToURL( url )
        }
    }
    
    
    // MARK: - MustangDocument internal
    
    /*==========================================================================*/
    fileprivate func importFromURL( _ URL: Foundation.URL ) {
        
        guard let managedObjectContext = self.managedObjectContext else {
            fatalError( "failed to obtain managed object context" )
        }
        
        guard let hidDictionary = NSDictionary( contentsOf: URL ) else {
            Swift.print( "\(URL) does not contain an archived dictionary" )
            return
        }
        
        guard let usagePagesDict = hidDictionary[HIDManagerKeys.usagePagesKey] as? [String:[String:AnyObject]] else {
            Swift.print( "Archived dictionary does not contain a '\(HIDManagerKeys.usagePagesKey)' value at its root" )
            return
        }
        
        managedObjectContext.performAndWait { 
            
            for ( usagePageKey, usagePageDict ) in usagePagesDict {
                
                let pageScanner = Scanner( string: usagePageKey )
                var usagePage: UInt32 = 0
                guard pageScanner.scanHexInt32( &usagePage ) else {
                    Swift.print( "Usage page key '\(usagePageKey) does not contain a hex value" )
                    continue
                }
                
                guard let usagePageName = usagePageDict[HIDManagerKeys.usagePageNameKey] as? String else {
                    Swift.print( "Dictionary for usage page '\(usagePageKey) does not contain a '\(HIDManagerKeys.usagePageNameKey)' value" )
                    continue
                }
                
                let usageNameFormat = usagePageDict[HIDManagerKeys.usageNameFormatKey] as? String
                
                let newUsagePage = NSEntityDescription.insertNewObject( forEntityName: UsagePageEntityKeys.entityName, into: managedObjectContext )
                newUsagePage.setValue( Int(usagePage), forKey: UsagePageEntityKeys.usagePageKey )
                newUsagePage.setValue( usagePageName, forKey: UsagePageEntityKeys.nameKey )
                newUsagePage.setValue( usageNameFormat, forKey: UsagePageEntityKeys.usageNameFormatKey )
                
                guard let usagesDict = usagePageDict[HIDManagerKeys.usagesKey] as? [String:[String:AnyObject]] else { continue }
                
                for ( usageKey, usageDict ) in usagesDict {
                    
                    let usageScanner = Scanner( string: usageKey )
                    var usage: UInt32 = 0
                    if usageScanner.scanHexInt32( &usage ) == false { continue }
                    
                    guard let usageName = usageDict[HIDManagerKeys.usageNameKey] as? String else {
                        Swift.print( "Dictionary for usage '\(usagePageKey):\(usageKey) does not contain a '\(HIDManagerKeys.usageNameKey)' value" )
                        continue
                    }
                    
                    let newUsage = NSEntityDescription.insertNewObject( forEntityName: UsageEntityKeys.entityName, into: managedObjectContext )
                    newUsage.setValue( newUsagePage, forKey: UsageEntityKeys.usagePageKey )
                    newUsage.setValue( Int(usage), forKey: UsageEntityKeys.usageKey )
                    newUsage.setValue( usageName, forKey: UsageEntityKeys.nameKey )
                    
                    if let collectionType = usageDict[HIDManagerKeys.collectionTypeKey] as? String {
                        newUsage.setValue( MustangDocument.collectionTypeNames.index( of: collectionType ), forKey: UsageEntityKeys.collectionTypeKey )
                    }
                    
                    if let spurious = usageDict[HIDManagerKeys.spuriousKey] as? Bool {
                        newUsage.setValue( spurious, forKey: UsageEntityKeys.spuriousKey )
                    }
                    
                    if let doubtful = usageDict[HIDManagerKeys.doubtfulKey] as? Bool {
                        newUsage.setValue( doubtful, forKey: UsageEntityKeys.doubtfulKey )
                    }
                }
            }
        }
    }
    
    /*==========================================================================*/
    fileprivate func exportToURL( _ URL: Foundation.URL ) {
        
        guard let managedObjectContext = self.managedObjectContext else {
            fatalError( "failed to obtain managed object context" )
        }
        
        var localError: NSError? = nil
        
        let rootDictionary = NSMutableDictionary()
        let usagePagesDict = NSMutableDictionary()
        rootDictionary[HIDManagerKeys.usagePagesKey] = usagePagesDict
        
        managedObjectContext.performAndWait {
            
            let usagePageRequest = NSFetchRequest<NSFetchRequestResult>()
            usagePageRequest.entity = NSEntityDescription.entity( forEntityName: UsagePageEntityKeys.entityName, in: managedObjectContext )
            
            do {
                
                let usagePageResult = try managedObjectContext.fetch( usagePageRequest )
                
                for usagePageEntity in usagePageResult  {
                    
                    let usagePage = (usagePageEntity as AnyObject).value( forKey: UsagePageEntityKeys.usagePageKey ) as! Int
                    
                    let usagePageDict = NSMutableDictionary()
                    let usagePageKey = String( format: "0x%04lX", usagePage )
                    usagePagesDict[usagePageKey] = usagePageDict
                    
                    let usagePageName = (usagePageEntity as AnyObject).value( forKey: UsagePageEntityKeys.nameKey ) as! String
                    usagePageDict[HIDManagerKeys.usagePageNameKey] = usagePageName
                    
                    if let usageNameFormat = (usagePageEntity as AnyObject).value( forKey: UsagePageEntityKeys.usageNameFormatKey ) {
                        usagePageDict[HIDManagerKeys.usageNameFormatKey] = usageNameFormat
                    }
                    
                    let usagesDict = NSMutableDictionary()
                    
                    guard let usageEntities = (usagePageEntity as AnyObject).value( forKey: UsagePageEntityKeys.usagesKey ) as? NSSet else { continue }
                    
                    for usageEntity in usageEntities {
                        
                        let usage = (usageEntity as AnyObject).value( forKey: UsageEntityKeys.usageKey ) as! Int
                        
                        let usageDict = NSMutableDictionary()
                        let usageKey = String( format: "0x%04lX", usage )
                        usagesDict[usageKey] = usageDict
                        
                        let usageName = (usageEntity as AnyObject).value( forKey: UsageEntityKeys.nameKey )
                        usageDict[HIDManagerKeys.usageNameKey] = usageName
                        
                        if let collectionType = (usageEntity as AnyObject).value( forKey: UsageEntityKeys.collectionTypeKey ) as? Int {
                            
                            if collectionType > 0 {
                                usageDict[HIDManagerKeys.collectionTypeKey] = MustangDocument.collectionTypeNames[collectionType]
                            }
                        }
                        
                        if let doubtful = (usageEntity as AnyObject).value( forKey: UsageEntityKeys.doubtfulKey ) as? Bool {
                            
                            if doubtful {
                                usageDict[HIDManagerKeys.doubtfulKey] = doubtful
                            }
                        }
                        
                        if let spurious = (usageEntity as AnyObject).value( forKey: UsageEntityKeys.spuriousKey) as? Bool {
                            
                            if spurious {
                                usageDict[HIDManagerKeys.spuriousKey] = spurious
                            }
                        }
                    }
                    
                    if usagesDict.count > 0 {
                        usagePageDict[HIDManagerKeys.usagesKey] = usagesDict
                    }
                }
                
            }
            catch {
                localError = error as NSError
            }
        }
        
        guard localError == nil else {
            Swift.print( localError! )
            return
        }
        
        do {
            let rootData = try PropertyListSerialization.data( fromPropertyList: rootDictionary, format: .binary, options: 0 )
            try? rootData.write( to: URL, options: [.atomic] )
        }
        catch {
            Swift.print( error )
        }
    }
    
    /*==========================================================================*/
    fileprivate func errorStringForErrors( _ errors: [NSError] ) -> String {
        
        let maxDisplayErrorCount = 5
        let totalErrorCount = errors.count
        let displayErrorCount = min( totalErrorCount, maxDisplayErrorCount )
        var errorString = ""
        
        if totalErrorCount > 1 {
            errorString = "There are \(totalErrorCount) validation errors:\n"
        }
        
        for error in errors[0..<displayErrorCount] {
            
            if let validationObject = error.userInfo[NSValidationObjectErrorKey] {
                if let usagePage = (validationObject as AnyObject).value( forKey: UsagePageEntityKeys.usagePageKey ) as? Int {
                    // Only a UsagePageEntity has a usagePage property as an Int
                    errorString += "Usage Page \(usagePage): "
                }
                else if let usage = (validationObject as AnyObject).value( forKey: UsageEntityKeys.usageKey ) as? Int {
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
