module Bridge::EcdsaK1 {
    use StarcoinFramework::Errors;
    use StarcoinFramework::Option;
    use StarcoinFramework::Secp256k1;

    const ERecoverFailed: u64 = 1;

    public fun decompress_pubkey(pubkey: &vector<u8>): vector<u8> {
        Secp256k1::decompress_pubkey(pubkey)
    }

    public fun secp256k1_ecrecover(signature: &vector<u8>, message: &vector<u8>, hash: u8): vector<u8> {
        let ecdsa_signature = Secp256k1::ecdsa_signature_from_bytes(*signature);
        let raw_publickey = Secp256k1::ecdsa_recover(*message, hash, &ecdsa_signature);
        assert!(Option::is_some(&raw_publickey), Errors::invalid_state(ERecoverFailed));
        Secp256k1::ecdsa_raw_public_key_to_bytes(&Option::destroy_some(raw_publickey))
    }
}
