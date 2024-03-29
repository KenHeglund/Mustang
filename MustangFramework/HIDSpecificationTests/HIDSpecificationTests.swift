/*===========================================================================
HIDSpecificationTests.swift
HIDSpecificationTests
Copyright (c) 2016,2023 OrderedBytes. All rights reserved.
===========================================================================*/

@testable import HIDSpecification
import IOKit.hid
import XCTest


class HIDSpecificationTests: XCTestCase {
	func testNames() {
		XCTAssertEqual(HIDSpecification.nameForUsagePage(kHIDPage_GenericDesktop), "Generic Desktop Controls")
		XCTAssertEqual(HIDSpecification.nameForUsagePage(kHIDPage_Simulation), "Simulation Controls")
		XCTAssertEqual(HIDSpecification.nameForUsagePage(6), "Generic Device Controls")
		XCTAssertEqual(HIDSpecification.nameForUsagePage(kHIDPage_KeyboardOrKeypad, usage: kHIDUsage_KeyboardHyphen), "Keyboard - and (underscore)")
		XCTAssertEqual(HIDSpecification.nameForUsagePage(kHIDPage_KeyboardOrKeypad, usage: kHIDUsage_Keypad6), "Keypad 6 and Right Arrow")
		XCTAssertEqual(HIDSpecification.nameForUsagePage(kHIDPage_Button, usage: 77), "Button #77")
		XCTAssertNil(HIDSpecification.nameForUsagePage(23))
		XCTAssertNil(HIDSpecification.nameForUsagePage(kHIDPage_GenericDesktop, usage: 1324))
	}
	
	func testStandardUsage() {
		XCTAssertTrue(HIDSpecification.isStandardUsagePage(kHIDPage_KeyboardOrKeypad, usage: kHIDUsage_KeyboardF1))
		XCTAssertTrue(HIDSpecification.isStandardUsagePage(kHIDPage_Button, usage: 77))
		XCTAssertFalse(HIDSpecification.isStandardUsagePage(kHIDPage_Button, usage: 0))
		XCTAssertFalse(HIDSpecification.isStandardUsagePage(0, usage: kHIDUsage_KeyboardF1))
		XCTAssertFalse(HIDSpecification.isStandardUsagePage(kHIDPage_GenericDesktop, usage: 10))
	}
}
