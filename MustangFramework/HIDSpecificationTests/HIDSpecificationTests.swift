/*===========================================================================
 HIDSpecificationTests.swift
 HIDSpecificationTests
 Copyright (c) 2016 OrderedBytes. All rights reserved.
 ===========================================================================*/

import XCTest
import IOKit.hid
@testable import HIDSpecification

/*==========================================================================*/

class HIDSpecificationTests: XCTestCase {
    
    /*==========================================================================*/
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    /*==========================================================================*/
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    /*==========================================================================*/
    func testNames() {
        XCTAssertEqual( HIDSpecification.nameForUsagePage( kHIDPage_GenericDesktop ), "Generic Desktop Controls" )
        XCTAssertEqual( HIDSpecification.nameForUsagePage( kHIDPage_Simulation ), "Simulation Controls" )
        XCTAssertEqual( HIDSpecification.nameForUsagePage( 6 ), "Generic Device Controls" )
        XCTAssertEqual( HIDSpecification.nameForUsagePage( kHIDPage_KeyboardOrKeypad, usage: kHIDUsage_KeyboardHyphen ), "Keyboard - and (underscore)" )
        XCTAssertEqual( HIDSpecification.nameForUsagePage( kHIDPage_KeyboardOrKeypad, usage: kHIDUsage_Keypad6 ), "Keypad 6 and Right Arrow" )
        XCTAssertEqual( HIDSpecification.nameForUsagePage( kHIDPage_Button, usage: 77 ), "Button #77" )
        XCTAssertNil( HIDSpecification.nameForUsagePage( 23 ) )
        XCTAssertNil( HIDSpecification.nameForUsagePage( kHIDPage_GenericDesktop, usage: 1324 ) )
    }
    
    /*==========================================================================*/
    func testStandardUsage() {
        XCTAssertTrue( HIDSpecification.isStandardUsagePage( kHIDPage_KeyboardOrKeypad, usage: kHIDUsage_KeyboardF1 ) )
        XCTAssertTrue( HIDSpecification.isStandardUsagePage( kHIDPage_Button, usage: 77 ) )
        XCTAssertFalse( HIDSpecification.isStandardUsagePage( kHIDPage_Button, usage: 0 ) )
        XCTAssertFalse( HIDSpecification.isStandardUsagePage( 0, usage: kHIDUsage_KeyboardF1 ) )
        XCTAssertFalse( HIDSpecification.isStandardUsagePage( kHIDPage_GenericDesktop, usage: 10 ) )
    }
}
