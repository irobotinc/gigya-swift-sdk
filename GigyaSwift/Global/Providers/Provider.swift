//
//  Provider.swift
//  GigyaSwift
//
//  Created by Shmuel, Sagi on 14/04/2019.
//  Copyright © 2019 Gigya. All rights reserved.
//

import UIKit

protocol Provider: class {
    
    var delegate: BusinessApiDelegate? { get set }

    func login<T: Codable>(type: T.Type, params: [String: Any], viewController: UIViewController?,
                           loginMode: String, completion: @escaping (GigyaApiResult<T>) -> Void)

    func logout()

    func getProviderSessions(token: String, expiration: String?) -> String

    var didFinish: () -> Void { get set }

}

extension Provider {

    func loginSuccess<T: Codable>(providerSessions: String, loginMode: String,
                                  params: [String: Any], completion: @escaping (GigyaApiResult<T>) -> Void) {
        GigyaLogger.log(with: self, message: "start LoginSuccess - providerSessions: \(providerSessions)")

        let newParams = ["providerSessions": providerSessions, "loginMode": loginMode]
                        .merging(params) { (_, new) in new }

        delegate?.callNativeSocialLogin(params: newParams) { result in
            completion(result!)
        }
    }

    func loginFailed<T: Codable>(error: String, completion: @escaping (GigyaApiResult<T>) -> Void) {
        GigyaLogger.log(with: self, message: "[loginFailed] - error: \(error)")
        
        completion(.failure(.providerError(data: error)))
    }

}
