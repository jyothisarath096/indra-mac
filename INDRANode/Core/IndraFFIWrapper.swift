// IndraFFIWrapper.swift
// Direct Swift declarations of C functions from libindra_ffi.
// Uses @_silgen_name for Xcode 26 explicit module compatibility.

import Foundation

// MARK: - Constants
let INDRA_OK:                Int32 = 0
let INDRA_ERR_NULL_POINTER:  Int32 = -1
let INDRA_ERR_BUFFER_SMALL:  Int32 = -2
let INDRA_ERR_INVALID_HEX:   Int32 = -3
let INDRA_ERR_KEYGEN:        Int32 = -4
let INDRA_ERR_TX_BUILD:      Int32 = -5
let INDRA_ERR_SIGN:          Int32 = -6
let INDRA_ERR_RANGE_PROOF:   Int32 = -7
let INDRA_ERR_BALANCE:       Int32 = -8
let INDRA_ERR_INVALID_PARAM: Int32 = -9
let INDRA_ERR_INTERNAL:      Int32 = -99

let INDRA_MNEMONIC_MAX_BYTES: Int = 300

// MARK: - IndraKeyPairBuffer
// Mirrors C struct layout exactly using a raw byte buffer.
// Total: 32 (validator_id) + 32 (classical_pk) + 1312 (pq_pk)
//      + 32 (classical_seed) + 2560 (pq_sk) + 32 (bls_seed)
//      + 32 (vrf_seed) = 4032 bytes

final class IndraKeyPairBuffer {
    static let size = 32 + 32 + 1312 + 32 + 2560 + 32 + 32  // 4032 bytes
    var buffer: [UInt8]

    init() { buffer = [UInt8](repeating: 0, count: IndraKeyPairBuffer.size) }

    var validatorId:   [UInt8] { Array(buffer[0..<32]) }
    var classicalPk:   [UInt8] { Array(buffer[32..<64]) }
    var pqPk:          [UInt8] { Array(buffer[64..<1376]) }
    var classicalSeed: [UInt8] { Array(buffer[1376..<1408]) }
    var pqSk:          [UInt8] { Array(buffer[1408..<3968]) }
    var blsSeed:       [UInt8] { Array(buffer[3968..<4000]) }
    var vrfSeed:       [UInt8] { Array(buffer[4000..<4032]) }

    func withUnsafeMutablePointer<T>(_ body: (UnsafeMutablePointer<UInt8>) throws -> T) rethrows -> T {
        try buffer.withUnsafeMutableBytes { ptr in
            try body(ptr.baseAddress!.assumingMemoryBound(to: UInt8.self))
        }
    }
}

// MARK: - C Function Declarations

@_silgen_name("indra_generate_mnemonic")
func indra_generate_mnemonic(_ out_phrase: UnsafeMutablePointer<CChar>?, _ out_len: Int) -> Int32

@_silgen_name("indra_keygen_from_mnemonic")
func indra_keygen_from_mnemonic_raw(_ phrase: UnsafePointer<CChar>?, _ out: UnsafeMutablePointer<UInt8>?) -> Int32

@_silgen_name("indra_validate_mnemonic")
func indra_validate_mnemonic(_ phrase: UnsafePointer<CChar>?) -> Int32

@_silgen_name("indra_keygen")
func indra_keygen_raw(_ seed: UnsafePointer<UInt8>?, _ out: UnsafeMutablePointer<UInt8>?) -> Int32

@_silgen_name("indra_error_string")
func indra_error_string(_ error_code: Int32) -> UnsafePointer<CChar>?

// MARK: - Safe Swift wrappers

func indra_keygen_from_mnemonic(_ phrase: UnsafePointer<CChar>?, _ out: IndraKeyPairBuffer) -> Int32 {
    out.withUnsafeMutablePointer { ptr in
        indra_keygen_from_mnemonic_raw(phrase, ptr)
    }
}

// MARK: - High-level helpers

/// Generate a new 24-word BIP-39 mnemonic phrase.
func generateMnemonic() -> String? {
    var buffer = [CChar](repeating: 0, count: INDRA_MNEMONIC_MAX_BYTES)
    let result = indra_generate_mnemonic(&buffer, INDRA_MNEMONIC_MAX_BYTES)
    guard result == INDRA_OK else { return nil }
    return String(cString: buffer)
}

/// Validate a BIP-39 mnemonic phrase.
func validateMnemonic(_ phrase: String) -> Bool {
    phrase.withCString { ptr in
        indra_validate_mnemonic(ptr) == INDRA_OK
    }
}

/// Derive keypair from a 24-word mnemonic phrase.
/// Returns (validatorId, classicalPk, pqPk, classicalSeed, pqSk) or nil on failure.
func keypairFromMnemonic(_ phrase: String) -> IndraKeyPairBuffer? {
    let keys = IndraKeyPairBuffer()
    let result = phrase.withCString { ptr in
        indra_keygen_from_mnemonic(ptr, keys)
    }
    guard result == INDRA_OK else { return nil }
    return keys
}
