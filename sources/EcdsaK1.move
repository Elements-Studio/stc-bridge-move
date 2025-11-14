module Bridge::EcdsaK1 {
    use StarcoinFramework::Vector;

    public fun decompress_pubkey(_pubkey: &vector<u8>): vector<u8> {
        // TODO(VR) to implements
        Vector::empty()
    }

    public fun secp256k1_ecrecover(_signature: &vector<u8>, _message: &vector<u8>, _hash: u8): vector<u8> {
        // TODO:(VR): to implements this function
        Vector::empty<u8>()
    }

}
