// Copyright (c) Starcoin Contributors
// SPDX-License-Identifier: Apache-2.0

module Bridge::Crypto {

    use StarcoinFramework::Vector;

    public fun ecdsa_pub_key_to_eth_address(_compressed_pub_key: &vector<u8>): vector<u8> {
        // TODO(VR): Add implementation code
        // // Decompress pub key
        // let decompressed = ecdsa_k1::decompress_pubkey(compressed_pub_key);
        //
        // // Skip the first byte
        // let (mut i, mut decompressed_64) = (1, vector[]);
        // while (i < 65) {
        //     decompressed_64.push_back(decompressed[i]);
        //     i = i + 1;
        // };
        //
        // // Hash
        // let hash = keccak256(&decompressed_64);
        //
        // // Take last 20 bytes
        // let address = vector[];
        // let i = 12;
        // while (i < 32) {
        //     address.push_back(hash[i]);
        //     i = i + 1;
        // };
        // address
        Vector::empty()
    }

    #[test]
    fun test_pub_key_to_eth_address() {
        let validator_pub_key = x"029bef8d556d80e43ae7e0becb3a7e6838b95defe45896ed6075bb9035d06c9964";
        let expected_address = x"b14d3c4f5fbfbcfb98af2d330000d49c95b93aa7";

        assert!(ecdsa_pub_key_to_eth_address(&validator_pub_key) == expected_address);
    }
}
