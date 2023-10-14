/*===========================================================================
 Entity.swift
 Mustang
 Copyright (c) 2020,2023 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Foundation


enum Entity {
	enum UsagePage {
		static let entityName = "UsagePageEntity"
		static let usagePageKey = "usagePage"
		static let nameKey = "name"
		static let usageNameFormatKey = "usageNameFormat"
		static let usagesKey = "usages"
	}
	
	enum Usage {
		static let entityName = "UsageEntity"
		static let usageKey = "usage"
		static let nameKey = "name"
		static let usagePageKey = "usagePage"
		static let collectionTypeKey = "collectionType"
	}
}
