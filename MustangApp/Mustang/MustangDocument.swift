/*===========================================================================
 MustangDocument.swift
 Mustang
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Cocoa

/*==========================================================================*/

struct UsagePageEntity {
    static let entityName = "UsagePageEntity"
    static let usagePageKey = "usagePage"
    static let nameKey = "name"
    static let usageNameFormatKey = "usageNameFormat"
    static let usagesKey = "usages"
}

struct UsageEntity {
    static let entityName = "UsageEntity"
    static let usageKey = "usage"
    static let nameKey = "name"
    static let usagePageKey = "usagePage"
    static let collectionTypeKey = "collectionType"
}

fileprivate struct HIDManager {
    static let usagePagesKey = "UsagePages"
    static let usagePageNameKey = "PageName"
    static let usagesKey = "Usages"
    static let usageNameKey = "UsageName"
    static let usageNameFormatKey = "UsageNameFormat"
    static let collectionTypeKey = "Collection"
}

/*==========================================================================*/

class MustangDocument: NSPersistentDocument {
    
    private static let defaultUsagePageTableSortKey = "usagePage"
    private static let defaultUsageTableSortKey = "usage"
    private static let usagePageTableSortDescriptorKey = "UsagePageTableSortDescriptors"
    private static let usageTableSortDescriptorKey = "UsageTableSortDescriptors"
    
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
        
        _ = MustangDocument.classInitialized
        
        let persistentStoreCoordinator = self.managedObjectContext?.persistentStoreCoordinator
        let managedObjectContext = NSManagedObjectContext( concurrencyType: .mainQueueConcurrencyType )
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        self.managedObjectContext = managedObjectContext
    }
    
    
    // MARK: - NSDocument overrides
    
    /*==========================================================================*/
    override class var autosavesInPlace: Bool {
        return false
    }
    
    /*==========================================================================*/
    override func makeWindowControllers() {
        
        let storyboardName = NSStoryboard.Name(rawValue: "Main")
        let storyboard = NSStoryboard( name: storyboardName, bundle: nil )
        let identifier = NSStoryboard.SceneIdentifier(rawValue: "MustangDocument Window Controller")
        let windowController = storyboard.instantiateController( withIdentifier: identifier ) as! NSWindowController
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
    override func write( to absoluteURL: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType, originalContentsURL absoluteOriginalContentsURL: URL? ) throws {
        
        // Handle only the case where a SaveAs is being performed and an existing URL is present, defer to the superclass for everything else.
        
        guard saveOperation == .saveAsOperation else {
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
        
        openPanel.beginSheetModal( for: window ) { ( result: NSApplication.ModalResponse ) in
            
            guard result == .OK else { return }
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
        
        savePanel.beginSheetModal( for: window ) { ( result: NSApplication.ModalResponse ) in
            
            guard result == .OK else { return }
            guard let url = savePanel.url else { return }
            
            self.exportToURL( url )
        }
    }
    
    
    // MARK: - MustangDocument internal

    /*==========================================================================*/
    private static let classInitialized: Bool = {
        
        let usagePageDescriptor = NSSortDescriptor( key: MustangDocument.defaultUsagePageTableSortKey, ascending: true, selector: #selector(NSNumber.compare(_:)) )
        let usagePageData = NSKeyedArchiver.archivedData( withRootObject: [usagePageDescriptor] )
        
        let usageDescriptor = NSSortDescriptor( key: MustangDocument.defaultUsageTableSortKey, ascending: true, selector: #selector(NSNumber.compare(_:)) )
        let usageData = NSKeyedArchiver.archivedData( withRootObject: [usageDescriptor] )
        
        let defaultDict = [
            MustangDocument.usagePageTableSortDescriptorKey : usagePageData,
            MustangDocument.usageTableSortDescriptorKey : usageData,
        ]
        
        UserDefaults.standard.register( defaults: defaultDict )
        
        return true
    }()
    
    /*==========================================================================*/
    fileprivate func importFromURL( _ URL: Foundation.URL ) {
        
        guard let managedObjectContext = self.managedObjectContext else {
            fatalError( "failed to obtain managed object context" )
        }
        
        guard let hidDictionary = NSDictionary( contentsOf: URL ) else {
            Swift.print( "\(URL) does not contain an archived dictionary" )
            return
        }
        
        guard let usagePagesDict = hidDictionary[HIDManager.usagePagesKey] as? [String:[String:AnyObject]] else {
            Swift.print( "Archived dictionary does not contain a '\(HIDManager.usagePagesKey)' value at its root" )
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
                
                guard let usagePageName = usagePageDict[HIDManager.usagePageNameKey] as? String else {
                    Swift.print( "Dictionary for usage page '\(usagePageKey) does not contain a '\(HIDManager.usagePageNameKey)' value" )
                    continue
                }
                
                let usageNameFormat = usagePageDict[HIDManager.usageNameFormatKey] as? String
                
                let newUsagePage = NSEntityDescription.insertNewObject( forEntityName: UsagePageEntity.entityName, into: managedObjectContext )
                newUsagePage.setValue( Int(usagePage), forKey: UsagePageEntity.usagePageKey )
                newUsagePage.setValue( usagePageName, forKey: UsagePageEntity.nameKey )
                newUsagePage.setValue( usageNameFormat, forKey: UsagePageEntity.usageNameFormatKey )
                
                guard let usagesDict = usagePageDict[HIDManager.usagesKey] as? [String:[String:AnyObject]] else { continue }
                
                for ( usageKey, usageDict ) in usagesDict {
                    
                    let usageScanner = Scanner( string: usageKey )
                    var usage: UInt32 = 0
                    if usageScanner.scanHexInt32( &usage ) == false { continue }
                    
                    guard let usageName = usageDict[HIDManager.usageNameKey] as? String else {
                        Swift.print( "Dictionary for usage '\(usagePageKey):\(usageKey) does not contain a '\(HIDManager.usageNameKey)' value" )
                        continue
                    }
                    
                    let newUsage = NSEntityDescription.insertNewObject( forEntityName: UsageEntity.entityName, into: managedObjectContext )
                    newUsage.setValue( newUsagePage, forKey: UsageEntity.usagePageKey )
                    newUsage.setValue( Int(usage), forKey: UsageEntity.usageKey )
                    newUsage.setValue( usageName, forKey: UsageEntity.nameKey )
                    
                    if let collectionType = usageDict[HIDManager.collectionTypeKey] as? String {
                        newUsage.setValue( MustangDocument.collectionTypeNames.index( of: collectionType ), forKey: UsageEntity.collectionTypeKey )
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
        rootDictionary[HIDManager.usagePagesKey] = usagePagesDict
        
        managedObjectContext.performAndWait {
            
            let usagePageRequest = NSFetchRequest<NSFetchRequestResult>()
            usagePageRequest.entity = NSEntityDescription.entity( forEntityName: UsagePageEntity.entityName, in: managedObjectContext )
            
            do {
                
                let usagePageResult = try managedObjectContext.fetch( usagePageRequest )
                
                for usagePageEntity in usagePageResult  {
                    
                    let usagePage = (usagePageEntity as AnyObject).value( forKey: UsagePageEntity.usagePageKey ) as! Int
                    
                    let usagePageDict = NSMutableDictionary()
                    let usagePageKey = String( format: "0x%04lX", usagePage )
                    usagePagesDict[usagePageKey] = usagePageDict
                    
                    let usagePageName = (usagePageEntity as AnyObject).value( forKey: UsagePageEntity.nameKey ) as! String
                    usagePageDict[HIDManager.usagePageNameKey] = usagePageName
                    
                    if let usageNameFormat = (usagePageEntity as AnyObject).value( forKey: UsagePageEntity.usageNameFormatKey ) {
                        usagePageDict[HIDManager.usageNameFormatKey] = usageNameFormat
                    }
                    
                    let usagesDict = NSMutableDictionary()
                    usagePageDict[HIDManager.usagesKey] = usagesDict
                    
                    guard let usageEntities = (usagePageEntity as AnyObject).value( forKey: UsagePageEntity.usagesKey ) as? NSSet else { continue }
                    
                    for usageEntity in usageEntities {
                        
                        let usage = (usageEntity as AnyObject).value( forKey: UsageEntity.usageKey ) as! Int
                        
                        let usageDict = NSMutableDictionary()
                        let usageKey = String( format: "0x%04lX", usage )
                        usagesDict[usageKey] = usageDict
                        
                        let usageName = (usageEntity as AnyObject).value( forKey: UsageEntity.nameKey )
                        usageDict[HIDManager.usageNameKey] = usageName
                        
                        if let collectionType = (usageEntity as AnyObject).value( forKey: UsageEntity.collectionTypeKey ) as? Int {
                            
                            if collectionType > 0 {
                                usageDict[HIDManager.collectionTypeKey] = MustangDocument.collectionTypeNames[collectionType]
                            }
                        }
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
                if let usagePage = (validationObject as AnyObject).value( forKey: UsagePageEntity.usagePageKey ) as? Int {
                    // Only a UsagePageEntity has a usagePage property as an Int
                    errorString += "Usage Page \(usagePage): "
                }
                else if let usage = (validationObject as AnyObject).value( forKey: UsageEntity.usageKey ) as? Int {
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
