// Copyright (c) Starcoin Contributors
// SPDX-License-Identifier: Apache-2.0

module Bridge::Crypto {

    use Bridge::EcdsaK1;

    public fun ecdsa_pub_key_to_eth_address(compressed_pub_key: &vector<u8>): vector<u8> {
        EcdsaK1::decompress_pubkey(compressed_pub_key)
    }

    #[test]
    fun test_pub_key_to_eth_address() {
        let validator_pub_key = x"029bef8d556d80e43ae7e0becb3a7e6838b95defe45896ed6075bb9035d06c9964";
        let expected_address = x"b14d3c4f5fbfbcfb98af2d330000d49c95b93aa7";

        assert!(ecdsa_pub_key_to_eth_address(&validator_pub_key) == expected_address, 1);
    }
}
