//
//  BiometricService.swift
//  Gigya
//
//  Created by Shmuel, Sagi on 08/07/2019.
//  Copyright © 2019 Gigya. All rights reserved.
//

import Foundation

class BiometricService: IOCBiometricServiceProtocol, BiometricServiceInternalProtocol {

    let config: GigyaConfig

    let sessionService: IOCSessionServiceProtocol

    /**
     Returns the indication if the session was opted-in.
     */

    var isOptIn: Bool {
        return config.biometricAllow ?? false
    }

    /**
     Returns the indication if the session is locked.
     */

    var isLocked: Bool {
        return config.biometricLocked ?? false
    }

    init(config: GigyaConfig, sessionService: IOCSessionServiceProtocol) {
        self.sessionService = sessionService
        self.config = config
    }

    // MARK: - Biometric

    /**
     Opt-in operation.
     Encrypt session with your biometric method.

     - Parameter completion:  Response GigyaApiResult<T>.
     */
    public func optIn(completion: @escaping (GigyaBiometricResult) -> Void) {
        sessionService.setSessionAs(biometric: true) { [weak self] (result) in
            switch result {
            case .success:
                self?.setBiometricEnable(to: true)

                completion(.success)
            case .failure:
                completion(.failure)
            }
        }
    }

    /**
     Opt-out operation.
     Decrypt session with your biometric method.

     - Parameter completion:  Response GigyaApiResult<T>.
     */
    public func optOut(completion: @escaping (GigyaBiometricResult) -> Void) {
        sessionService.setSessionAs(biometric: false) { [weak self] (result) in
            switch result {
            case .success:
                self?.setBiometricEnable(to: false)

                completion(.success)
            case .failure:
                completion(.failure)
            }
        }
    }

    /**
     Unlock operation.
     Decrypt session and save as default.

     - Parameter completion:  Response GigyaBiometricResult.
     */
    public func unlockSession(completion: @escaping (GigyaBiometricResult) -> Void) {
        guard config.biometricAllow == true else {
            GigyaLogger.log(with: "biometric", message: "can't load session because user don't opt in")
            completion(.failure)
            return
        }

        sessionService.getSession(biometric: false) { (success) in
            if success == true {
                completion(.success)
            } else {
                completion(.failure)
            }
        }
    }

    /**
     Lock operation
     Clear current heap session. Does not require biometric authentication.

     - Parameter completion:  Response GigyaBiometricResult.
     */
    public func lockSession(completion: @escaping (GigyaBiometricResult) -> Void) {
        if isOptIn {
            sessionService.clearSession()
            setBiometricLocked(to: true)
            completion(.success)
        } else {
            GigyaLogger.log(with: "biometric", message: "can't lock session because user don't opt in")

            completion(.failure)
        }
    }

    // Mark: - Internal functions

    internal func clearBiometric() {
        setBiometricEnable(to: false)
        setBiometricLocked(to: false)
    }

    private func setBiometricEnable(to allow: Bool) {
        UserDefaults.standard.setValue(allow, forKey: InternalConfig.Storage.biometricAllow)

        UserDefaults.standard.synchronize()
    }

    private func setBiometricLocked(to enable: Bool) {
        UserDefaults.standard.setValue(enable, forKey: InternalConfig.Storage.biometricLocked)

        UserDefaults.standard.synchronize()
    }
}