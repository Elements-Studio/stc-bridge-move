// Copyright (c) Starcoin Contributors
// SPDX-License-Identifier: Apache-2.0

module Bridge::BCSUtils {
    use StarcoinFramework::BitOperators;
    use StarcoinFramework::Errors;
    use StarcoinFramework::Vector;

    const EOutOfRange: u64 = 1;
    const ELenOutOfRange: u64 = 2;
    const ENotBool: u64 = 3;

    // left shift n bits.
    public fun lshift_u128(x: u128, n: u8): u128 {
        (x << n)
    }

    // right shift n bits.
    public fun rshift_u128(x: u128, n: u8): u128 {
        (x >> n)
    }

    fun peel_vec_length(bcs: &mut vector<u8>): u64 {
        let (total, shift, len) = (0u64, 0, 0);
        loop {
            assert!(len <= 4, ELenOutOfRange);
            let byte = Vector::pop_back(bcs);
            len = len + 1;
            total = total | (((byte & 0x7f) << shift) as u64);
            if ((byte & 0x80) == 0) break;
            shift = shift + 7;
        };
        total
    }

    public fun peel_bool(bcs: &mut vector<u8>): bool {
        let value = Self::peel_u8(bcs);
        if (value == 0) {
            false
        } else if (value == 1) {
            true
        } else {
            abort ENotBool
        }
    }


    public fun peel_u8(bcs: &mut vector<u8>): u8 {
        assert!(Vector::length(bcs) >= 1, Errors::limit_exceeded(EOutOfRange));
        Vector::pop_back(bcs)
    }

    public fun peel_u16(bcs: &mut vector<u8>): u16 {
        assert!(Vector::length(bcs) >= 2, EOutOfRange);
        let value: u16 = 0;
        let i: u8 = 0;
        while (i < 16) {
            let byte = (Vector::pop_back(bcs) as u16);
            value = value + (byte << i);
            i = i + 8;
        };
        value
    }

    /// Read `u64` value from bcs-serialized bytes.
    public fun peel_u64(bcs: &mut vector<u8>): u64 {
        assert!(Vector::length(bcs) >= 8, EOutOfRange);
        let value: u64 = 0;
        let i: u8 = 0;
        while (i < 64) {
            let byte = (Vector::pop_back(bcs) as u64);
            value = value + (byte << i);
            i = i + 8;
        };
        value
    }

    /// Read `u128` value from bcs-serialized bytes.
    public fun peel_u128(bcs: &mut vector<u8>): u128 {
        assert!(Vector::length(bcs) >= 16, EOutOfRange);

        let value: u128 = 0;
        let i: u8 = 0;
        while (i < 128) {
            let byte = (Vector::pop_back(bcs) as u128);
            value = value + (byte << i);
            i = i + 8;
        };

        value
    }

    /// Read `u256` value from bcs-serialized bytes.
    public fun peel_u256(bcs: &mut vector<u8>): u256 {
        assert!(Vector::length(bcs) >= 32, EOutOfRange);

        let value: u256 = 0;
        let i: u256 = 0;
        while (i < 256) {
            let byte = (Vector::pop_back(bcs) as u256);
            value = value + (byte << (i as u8));
            i = i + 8;
        };
        value
    }


    /// Peel a vector of `u8` (eg string) from serialized bytes.
    public fun peel_vec_u8(bcs: &mut vector<u8>): vector<u8> {
        let len = Self::peel_vec_length(bcs);
        let v = vector[];
        let i = 0;
        while (i < len) {
            Vector::push_back(&mut v, Self::peel_u8(bcs));
            i = i + 1;
        };
        v
    }

    public fun peel_vec_u64(bcs: &mut vector<u8>): vector<u64> {
        let len = Self::peel_vec_length(bcs);
        let v = vector[];
        let i = 0;
        while (i < len) {
            Vector::push_back(&mut v, Self::peel_u64(bcs));
            i = i + 1;
        };
        v
    }

    /// Peel a `vector<vector<u8>>` (eg vec of string) from serialized bytes.
    public fun peel_vec_vec_u8(bcs: &mut vector<u8>): vector<vector<u8>> {
        let len = Self::peel_vec_length(bcs);

        let result = Vector::empty<vector<u8>>();
        let i = 0;
        while (i < len) {
            let inner_len = Self::peel_vec_length(bcs);
            let inner_vec = vector[];
            let j = 0;
            while (j < inner_len) {
                Vector::push_back(&mut inner_vec, Self::peel_u8(bcs));
                j = j + 1;
            };
            Vector::push_back(&mut result, inner_vec);
            i = i + 1;
        };
        result
    }

    public fun into_remainder_bytes(bcs: vector<u8>): vector<u8> {
        let result = copy bcs;
        Vector::reverse(&mut result);
        result
    }

    public fun slice(data: &vector<u8>, start: u64, end: u64): vector<u8> {
        let i = start;
        let result = Vector::empty<u8>();
        let data_len = Vector::length(data);
        let actual_end = if (end < data_len) {
            end
        } else {
            data_len
        };
        while (i < actual_end) {
            Vector::push_back(&mut result, *Vector::borrow(data, i));
            i = i + 1;
        };
        result
    }

    public fun slice_range_with_template<Element: copy>(data: &vector<Element>, start: u64, end: u64): vector<Element> {
        let i = start;
        let result = Vector::empty<Element>();
        let data_len = Vector::length(data);
        let actual_end = if (end < data_len) {
            end
        } else {
            data_len
        };
        while (i < actual_end) {
            Vector::push_back(&mut result, *Vector::borrow(data, i));
            i = i + 1;
        };
        result
    }

    public fun concat(v1: &vector<u8>, v2: vector<u8>): vector<u8> {
        let data = *v1;
        Vector::append(&mut data, v2);
        data
    }

    public fun get_bit(data: &vector<u8>, index: u64): bool {
        let pos = index / 8;
        let bit = (7 - index % 8);
        (*Vector::borrow(data, pos) >> (bit as u8)) & 1u8 != 0
    }

    public fun bytes_to_u64(data: &vector<u8>): u64 {
        let number: u64 = 0;
        let i = 0;
        let len = Vector::length(data);
        while (i < len) {
            let slice = *Vector::borrow(data, i);
            let bit = (len - (i + 1) as u8);
            //BitOperators::lshift return only u64
            number = number + BitOperators::lshift((slice as u64), bit * 8);
            i = i + 1;
        };
        number
    }

    // big endian cast
    public fun bytes_to_u128(data: &vector<u8>): u128 {
        let number: u128 = 0;
        let i = 0;
        let len = Vector::length(data);
        while (i < len) {
            let slice = *Vector::borrow(data, i);
            let bit = (len - (i + 1) as u8);
            number = number + lshift_u128((slice as u128), bit * 8);
            i = i + 1;
        };
        number
    }

    // little endian cast
    public fun bytes_reverse_to_u128(data: &vector<u8>): u128 {
        let number: u128 = 0;
        let len = Vector::length(data);
        if (len > 0) {
            let i = len - 1;
            loop {
                let slice = *Vector::borrow(data, i);
                let bit = (i as u8);
                number = number + lshift_u128((slice as u128), bit * 8);
                if (i == 0) {
                    break
                };
                i = i - 1;
            };
        };
        number
    }

    public fun left_padding(data: &vector<u8>, total_len: u64): vector<u8> {
        let origin_len = Vector::length(data);
        if (origin_len < total_len) {
            let padding_bytes = create_zero_bytes(total_len - origin_len);
            concat(&padding_bytes, *data)
        } else {
            *data
        }
    }

    public fun right_padding(data: &vector<u8>, total_len: u64): vector<u8> {
        let origin_len = Vector::length(data);
        if (origin_len < total_len) {
            let padding_bytes = create_zero_bytes(total_len - origin_len);
            data = &concat(data, padding_bytes);
        };
        *data
    }

    public fun create_zero_bytes(len: u64): vector<u8> {
        let i = 0 ;
        let bytes = Vector::empty();
        while (i < len) {
            bytes = concat(&bytes, x"00");
            i = i + 1;
        };
        bytes
    }
}

#[test_only]
module StarcoinFramework::BCSTest {
    use StarcoinFramework::BCS;
    use StarcoinFramework::Debug;
    use StarcoinFramework::STC;
    use StarcoinFramework::Token;

    struct CrossChainFeeLockEvent has store, drop {
        from_asset: Token::TokenCode,
        sender: address,
        to_chain_id: u64,
        to_address: vector<u8>,
        net: u128,
        fee: u128,
        id: u128,
    }

    #[test]
    public fun test_bcs_serialize() {
        let cc_fee_event = CrossChainFeeLockEvent {
            from_asset: Token::token_code<STC::STC>(),
            sender: @Bridge,
            to_chain_id: 11,
            to_address: x"18351d311d32201149a4df2a9fc2db8a", //*to_address,
            net: 111,
            fee: 222,
            id: 333,
        };
        let bs = BCS::to_bytes<CrossChainFeeLockEvent>(&cc_fee_event);
        Debug::print<vector<u8>>(&bs);
    }
}

#[test_only]
module StarcoinFramework::BCSUtilsTest {
    use Bridge::BCSUtils;
    use StarcoinFramework::BCS;
    use StarcoinFramework::Debug::Self;
    use StarcoinFramework::Vector;

    public fun slice(data: &vector<u8>, start: u64, end: u64): vector<u8> {
        let i = start;
        let result = Vector::empty<u8>();
        let data_len = Vector::length(data);
        let actual_end = if (end < data_len) {
            end
        } else {
            data_len
        };
        while (i < actual_end) {
            Vector::push_back(&mut result, *Vector::borrow(data, i));
            i = i + 1;
        };
        result
    }

    #[test]
    public fun test_bytes_to_u128() {
        // let hex:vector<u8> = x"98234aed82"; //653427142018
        let hex: vector<u8> = x"014e95f5a48100"; //8955205
        let number = BCSUtils::bytes_to_u128(&hex);
        Debug::print<u128>(&number);
        //        assert!(number == 653427142018, 1001);
        assert!(number == 367880955003136, 1001);
    }

    //    #[test, expected_failure(abort_code = 1)] //
    #[test, expected_failure]
    public fun test_cast_hex_u128_overflow() {
        let hex: vector<u8> = x"c4c8b2db715e9f7e1d3306b9f6860a389635dfb3943db13f1005544a50fbb2"; //
        let number = BCSUtils::bytes_to_u128(&hex);
        Debug::print<u128>(&number);
        //        assert!(number == 367880955003136, 1001);
    }

    #[test]
    public fun test_cast_hex_u128_bound() {
        let hex: vector<u8> = x"00"; //
        let number = BCSUtils::bytes_to_u128(&hex);
        Debug::print<u128>(&number);
    }

    #[test]
    public fun test_bytes_reverse_to_u128() {
        let hex: vector<u8> = x"014e95f5a48100"; //367880955003136
        let number = BCSUtils::bytes_to_u128(&hex);
        Debug::print(&hex);
        Vector::reverse(&mut hex);
        Debug::print(&hex);
        let reverse_number = BCSUtils::bytes_reverse_to_u128(&hex);
        Debug::print<u128>(&number);
        Debug::print<u128>(&reverse_number);
        assert!(number == 367880955003136, 1001);
        assert!(number == reverse_number, 1002);
    }

    #[test]
    public fun test_vector() {
        let hex: vector<u8> = x"014e95f5a48100"; //
        let hex1: vector<u8> = x"01"; //
        let hex2: vector<u8> = x"0166"; //
        //        let len = Vector::length(&hex);
        Debug::print<u64>(&Vector::length(&hex));
        Debug::print<u64>(&Vector::length(&hex1));
        Debug::print<u64>(&Vector::length(&hex2));
        Debug::print<vector<u8>>(&hex);
        Debug::print<vector<u8>>(&slice(&hex, 1, 12));
    }

    #[test]
    public fun test_bcs_cmp() {
        let hex1: vector<u8> = x"80"; //
        let hex2: vector<u8> = x"0305c9"; //
        let hex3: vector<u8> = x"0305c9"; //
        let data1 = BCS::to_bytes<u8>(&128u8);
        let data2 = BCS::to_bytes<u128>(&198089u128);
        let data3 = BCS::to_bytes<u64>(&198089u64);
        Debug::print<vector<u8>>(&hex1);
        Debug::print<vector<u8>>(&data1);
        Debug::print<vector<u8>>(&hex2);
        Debug::print<vector<u8>>(&data2);
        Debug::print<vector<u8>>(&hex3);
        Debug::print<vector<u8>>(&data3);
        assert!(data1 == hex1, 1003);
        assert!(data2 != copy hex2, 1004);
        assert!(data3 != hex3, 1005);

        Debug::print<u128>(&(BCSUtils::bytes_to_u128(&hex2)));
    }

    #[test]
    public fun test_padding() {
        let hex: vector<u8> = x"01234f";
        let _hex_left: vector<u8> = x"000000000001234f";
        let _hex_right: vector<u8> = x"01234f0000000000";
        let left_padding_bytes = BCSUtils::left_padding(&hex, 8);
        let right_padding_bytes = BCSUtils::right_padding(&hex, 8);
        assert!(_hex_left == copy left_padding_bytes, 1007);
        assert!(_hex_right == copy right_padding_bytes, 1008);
        Debug::print<vector<u8>>(&left_padding_bytes);
        Debug::print<vector<u8>>(&right_padding_bytes);
    }

    #[test]
    public fun test_bytes_equal() {
        let hex: vector<u8> = x"01234f";
        let hex2: vector<u8> = BCSUtils::concat(&x"01", x"234f");
        assert!(copy hex == copy hex2, 1009);
        assert!(&hex == &hex2, 1011);
    }

    #[test]
    public fun test_bcs_address() {
        //let addr = x"344CFC3B8635F72F14200AAF2168D9F75DF86FD3000000000000000000000000";
        let addr1 = x"344CFC3B8635F72F14200AAF2168D9F7";
        let converted_addr = BCS::to_address(addr1);
        Debug::print(&converted_addr);
        assert!(converted_addr != @0x01, 1001);
    }

    // Using python convert decimal array to hex string
    // ```
    // ''.join(str(e) for e in [('%02X' % x) for x in [247, 27, 85, 239, 85, 206, 220, 145, 253, 0, 127, 122, 155, 163, 134, 236, 151, 143, 58, 168]])
    // ```
    #[test]
    public fun test_bcs_equals1() {
        //let addr = x"344CFC3B8635F72F14200AAF2168D9F75DF86FD3000000000000000000000000";
        let bcs1 = x"F71B55EF55CEDC91FD007F7A9BA386EC978F3AA8";
        Debug::print(&bcs1);
    }
}