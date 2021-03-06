//
//  CaretakerUITest.swift
//  RemembralUITests
//
//  Created by Alwin Leong on 11/3/18.
//  Copyright © 2018 Aayush Malhotra. All rights reserved.
//

import XCTest

class CaretakerUITest: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCaretaker() {
        let app = XCUIApplication()
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let exists = NSPredicate(format: "exists == true")
        let loadCaretakerButton = app.buttons["Caretaker"]
        let buttonExpectation = expectation(for: exists, evaluatedWith: loadCaretakerButton, handler: nil)
        let result = XCTWaiter().wait(for: [buttonExpectation], timeout: 10)
        assert(result == .completed)
        
        loadCaretakerButton.tap()
    }
    
    func testThirdViewAccess(){
        let app = XCUIApplication()
        app.buttons["Caretaker"].tap()
        app.tabBars.buttons["Reminders"].tap()
        app.buttons["+ Add Reminder"].tap()
    }
}
