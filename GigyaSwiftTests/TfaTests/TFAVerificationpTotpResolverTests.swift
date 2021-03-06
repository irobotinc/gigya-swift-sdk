//
//  TFAVerificationpTotpResolverTests.swift
//  GigyaSwiftTests
//
//  Created by Shmuel, Sagi on 28/05/2019.
//  Copyright © 2019 Gigya. All rights reserved.
//

import XCTest
@testable import Gigya
@testable import GigyaTfa

class TFAVerificationpTotpResolverTests: XCTestCase {
    var ioc = GigyaContainerUtils.shared

    var businessApi: BusinessApiServiceProtocol?

    var resolver: VerifyTotpResolver<RequestTestModel>?

    override func setUp() {
        ioc = GigyaContainerUtils()

        businessApi =  ioc.container.resolve(BusinessApiServiceProtocol.self)

        ResponseDataTest.resData = nil
        ResponseDataTest.error = nil
        ResponseDataTest.errorCalled = 0
        ResponseDataTest.errorCalledCallBack = {}

    }

    func runTfaVerificationTotpResolver(with dic: [String: Any], callback: @escaping () -> () = {}, callback2: @escaping () -> () = {}, phone: String? = "123", errorCallback: @escaping (String) -> () = { _ in }) {
        // swiftlint:disable force_try
        let jsonData = try! JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
        // swiftlint:enable force_try

        let error = NSError(domain: "gigya", code: 403101, userInfo: ["callId": "dasdasdsad"])

        ResponseDataTest.error = error

        ResponseDataTest.resData = jsonData

        businessApi?.login(dataType: RequestTestModel.self, loginId: "tes@test.com", password: "151515", params: [:], completion: { (result) in
            switch result {
            case .success(let data):
                XCTAssertEqual(data.callId, dic["callId"] as! String)
            case .failure(let error):
                print(error) // general error
                if case .emptyResponse = error.error {
                    XCTAssert(true)
                    return
                }

                if case .jsonParsingError(let error) = error.error{
                    errorCallback(error.localizedDescription)
                }

                guard let interruption = error.interruption else {
                    if case .gigyaError(let eee) = error.error {
                        if eee.errorCode != 123 {
                            XCTFail()
                        }
                    }
                    return
                }
                // Evaluage interruption.
                switch interruption {
                case .pendingTwoFactorVerification(let interruption, let providers, let factory):
                    // Reference inactive providers (registration).
                    self.resolver = factory.getResolver(for: VerifyTotpResolver.self)
                    let activeProviders = providers!
                    XCTAssertNotEqual(activeProviders.count, 0)

                    callback()
                    self.resolver?.verifyTOTPCode(verificationCode: "123", rememberDevice: false, completion: { (result) in
                        switch result {
                        case .resolved:
                            XCTAssertTrue(true)
                        case .invalidCode:
                            errorCallback("invalidCode")
                        case .failed(let error):
                            errorCallback(error.localizedDescription)

                        }
                    })
                    callback2()

                default:
                    XCTFail()
                }
            }
        })
    }

    func testTfaSuccess() {
        let activeProviders = [["name": "gigyaTotp"]]
        let inactiveProviders = [["name": "livelink"]]
        let phones = [["id": "4324", "obfuscated": "432432", "lastMethod": "d"]]

        let dic: [String: Any] = ["errorCode": 0, "callId": "34324", "statusCode": 200, "gigyaAssertion": "123","phvToken": "123","providerAssertion": "123","regToken": "123","activeProviders": activeProviders, "inactiveProviders": inactiveProviders, "phones": phones]

        runTfaVerificationTotpResolver(with: dic)
    }

    func testTfaError() {
        let activeProviders = [["name": "gigyaTotp"]]
        let inactiveProviders = [["name": "error"]]
        let phones = [["id": "4324", "obfuscated": "432432", "lastMethod": "d"]]

        let dic: [String: Any] = ["errorCode": 0, "callId": "34324", "statusCode": 200, "gigyaAssertion": "123","phvToken": "123","providerAssertion": "123","regToken": "123","activeProviders": activeProviders, "inactiveProviders": inactiveProviders, "phones": phones]

        let expectation = self.expectation(description: "TOTPtestTfaError")

        runTfaVerificationTotpResolver(with: dic, errorCallback: { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        })

        self.waitForExpectations(timeout: 5, handler: nil)

    }

    func testTfaiVerifyError() {
        let activeProviders = [["name": "gigyaTotp"]]
        let inactiveProviders = [["name": "livelink"]]

        let dic: [String: Any] = ["errorCode": 0, "callId": "34324", "statusCode": 200, "gigyaAssertion": "123","phvToken": "123","providerAssertion": "123","regToken": "123","activeProviders": activeProviders, "inactiveProviders": inactiveProviders]

        let expectation = self.expectation(description: "TOTPtestTfaiVerifyError")

        runTfaVerificationTotpResolver(with: dic, callback2: {
            // swiftlint:disable force_try

            let dic: [String: Any] = ["errorCode": 123, "callId": "34324", "statusCode": 200]

            let jsonData = try! JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
            // swiftlint:enable force_try

            ResponseDataTest.resData = jsonData
            ResponseDataTest.error = nil
        }, errorCallback: { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        })

        self.waitForExpectations(timeout: 5, handler: nil)

    }

    func testTfaFinalizeError() {
        let activeProviders = [["name": "gigyaTotp"]]
        let inactiveProviders = [["name": "livelink"]]

        let dic: [String: Any] = ["errorCode": 0, "callId": "34324", "statusCode": 200, "gigyaAssertion": "123","phvToken": "123","providerAssertion": "123","regToken": "123","activeProviders": activeProviders, "inactiveProviders": inactiveProviders]

        let expectation = self.expectation(description: "TOTPtestTfaFinalizeError")

        runTfaVerificationTotpResolver(with: dic, callback2: {
            ResponseDataTest.errorCalledCallBack = {
                if ResponseDataTest.errorCalled == 5 {
                    // swiftlint:disable force_try
                    ResponseDataTest.errorCalled = -2
                    let dic: [String: Any] = ["errorCode": 123, "callId": "34324", "statusCode": 200]

                    let jsonData = try! JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
                    // swiftlint:enable force_try

                    ResponseDataTest.resData = jsonData
                    ResponseDataTest.error = nil

                }
            }
        }, errorCallback: { error in
            XCTAssertNotNil(error)
            expectation.fulfill()

        })

        self.waitForExpectations(timeout: 5, handler: nil)

    }

//    func testTfaWithoutAssertion() {
//        let activeProviders = [["name": "gigyaTotp"]]
//        let dic: [String: Any] = ["errorCode": 0, "callId": "34324", "statusCode": 200,"regToken": "123","activeProviders": activeProviders, "gigyaAssertion": ""]
//
//        let expectation = self.expectation(description: "TOTPtestTfaWithoutAssertion")
//
//        runTfaVerificationTotpResolver(with: dic, errorCallback: { error in
//            XCTAssertNotNil(error)
//            expectation.fulfill()
//
//        })
//        self.waitForExpectations(timeout: 5, handler: nil)
//
//    }
//
//    func testResolverVerifyCodenotSupprted() {
//        let inactiveProviders = [["name": "gigyaTotp"]]
//
//        let dic: [String: Any] = ["errorCode": 0, "callId": "34324", "statusCode": 200, "gigyaAssertion": "123","phvToken": "123","providerAssertion": "123","regToken": "123", "inactiveProviders": inactiveProviders]
//        // swiftlint:disable force_try
//        let jsonData = try! JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
//        // swiftlint:enable force_try
//
//        let error = NSError(domain: "gigya", code: 403101, userInfo: ["callId": "dasdasdsad"])
//
//        ResponseDataTest.error = error
//
//        ResponseDataTest.resData = jsonData
//
//        businessApi?.login(dataType: RequestTestModel.self, loginId: "tes@test.com", password: "151515", params: [:], completion: { (result) in
//            switch result {
//            case .success:
//                XCTFail()
//            case .failure(let error):
//                guard let interruption = error.interruption else {
//                    XCTAssert(true)
//                    return
//                }
//
//                switch interruption {
//                case .pendingTwoFactorVerification(let resolver):
//                    self.expectFatalError(expectedMessage: "[TFAVerificationResolver<RequestTestModel>]: totp is not supported in verification ") {
//                        resolver.verifyCode(provider: .totp, authenticationCode: "123")
//                    }
//                default:
//                    break
//                }
//            }
//
//        })
//
//    }
}
