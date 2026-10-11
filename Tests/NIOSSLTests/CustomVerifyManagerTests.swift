//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2026 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore
import NIOEmbedded
import XCTest

@_implementationOnly import CNIOBoringSSL
@_implementationOnly import CNIOBoringSSLShims

@testable import NIOSSL

final class CustomVerifyManagerTests: XCTestCase {
    // TLS AlertDescription.bad_certificate's wire value (RFC 5246 section 7.2).
    private let tlsBadCertificateAlert: UInt8 = 42

    private func makeConnection(server: Bool = false) throws -> (SSLConnection, EmbeddedEventLoop) {
        var configuration = TLSConfiguration.makeClientConfiguration()
        configuration.trustRoots = .certificates([])
        let context = try NIOSSLContext(configuration: configuration)
        let connection = context.createConnection()!
        if server {
            connection.setAcceptState()
        } else {
            connection.setConnectState()
        }
        let eventLoop = EmbeddedEventLoop()
        connection.eventLoop = eventLoop
        return (connection, eventLoop)
    }

    private func process(
        _ manager: CustomVerifyManager,
        runEventLoop: Bool = true,
        server: Bool = false
    ) throws -> (first: ssl_verify_result_t, second: ssl_verify_result_t?, alert: UInt8?) {
        let (connection, eventLoop) = try self.makeConnection(server: server)
        connection.customVerificationManager = manager

        let (first, firstAlert) = connection.customVerificationManager!.process(on: connection)

        guard runEventLoop else {
            return (first, nil, firstAlert)
        }

        eventLoop.run()
        let (second, alert) = connection.customVerificationManager!.process(on: connection)
        return (first, second, alert)
    }

    func testInternalFailureReturnsConfiguredAlert() throws {
        let expectedAlert = CNIOBoringSSLShims_SSL_AD_BAD_CERTIFICATE()
        let manager = CustomVerifyManager(
            callback: { promise in promise.succeed(.failed) },
            failureAlert: expectedAlert
        )

        let result = try self.process(manager)

        XCTAssertEqual(expectedAlert, self.tlsBadCertificateAlert)
        XCTAssertEqual(result.first, ssl_verify_retry)
        XCTAssertEqual(result.second, ssl_verify_invalid)
        XCTAssertEqual(result.alert, Optional(expectedAlert))
    }

    func testPublicFailureLeavesAlertUnspecified() throws {
        let callback: NIOSSLCustomVerificationCallback = { _, promise in
            promise.succeed(.failed)
        }
        let manager = CustomVerifyManager(callback: callback)

        let result = try self.process(manager)

        XCTAssertEqual(result.first, ssl_verify_retry)
        XCTAssertEqual(result.second, ssl_verify_invalid)
        XCTAssertNil(result.alert)
    }

    func testInternalServerFailureLeavesAlertUnspecified() throws {
        let manager = CustomVerifyManager(
            callback: { promise in promise.succeed(.failed) },
            failureAlert: CNIOBoringSSLShims_SSL_AD_BAD_CERTIFICATE()
        )

        let result = try self.process(manager, server: true)

        XCTAssertEqual(result.first, ssl_verify_retry)
        XCTAssertEqual(result.second, ssl_verify_invalid)
        XCTAssertNil(result.alert)
    }

    func testPublicMetadataFailureLeavesAlertUnspecified() throws {
        let callback: NIOSSLCustomVerificationCallbackWithMetadata = { _, promise in
            promise.succeed(.failed)
        }
        let manager = CustomVerifyManager(callback: callback)

        let result = try self.process(manager)

        XCTAssertEqual(result.first, ssl_verify_retry)
        XCTAssertEqual(result.second, ssl_verify_invalid)
        XCTAssertNil(result.alert)
    }

    func testInternalSuccessLeavesAlertUnchanged() throws {
        let manager = CustomVerifyManager(
            callback: { promise in promise.succeed(.certificateVerified) },
            failureAlert: CNIOBoringSSLShims_SSL_AD_BAD_CERTIFICATE()
        )

        let result = try self.process(manager)

        XCTAssertEqual(result.first, ssl_verify_retry)
        XCTAssertEqual(result.second, ssl_verify_ok)
        XCTAssertNil(result.alert)
    }

    func testPendingInternalVerificationLeavesAlertUnchanged() throws {
        let manager = CustomVerifyManager(
            callback: { _ in },
            failureAlert: CNIOBoringSSLShims_SSL_AD_BAD_CERTIFICATE()
        )

        let result = try self.process(manager, runEventLoop: false)

        XCTAssertEqual(result.first, ssl_verify_retry)
        XCTAssertNil(result.second)
        XCTAssertNil(result.alert)
    }

    func testDarwinDefaultTrustManagerUsesBadCertificateAlert() throws {
        #if canImport(Darwin)
        let context = try NIOSSLContext(configuration: .makeClientConfiguration())
        let connection = context.createConnection()!

        XCTAssertEqual(
            connection.customVerificationManager?.failureAlert,
            CNIOBoringSSLShims_SSL_AD_BAD_CERTIFICATE()
        )
        #endif
    }
}
