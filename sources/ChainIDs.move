// Copyright (c) Starcoin Contributors
// SPDX-License-Identifier: Apache-2.0

module Bridge::ChainIDs {

    use StarcoinFramework::Errors;
    use StarcoinFramework::Vector;
    use StarcoinFramework::ChainId;

    const ETH_MAINNET: u8 = 10;
    const ETH_SEPOLIA: u8 = 11;
    const ETH_CUSTOM: u8 = 12;

    const EInvalidBridgeRoute: u64 = 0;

    //////////////////////////////////////////////////////
    // Types
    //

    struct BridgeRoute has copy, drop, store {
        source: u8,
        destination: u8,
    }

    //////////////////////////////////////////////////////
    // Public functions
    //
    public fun eth_mainnet(): u8 { ETH_MAINNET }

    public fun eth_sepolia(): u8 { ETH_SEPOLIA }

    public fun eth_custom(): u8 { ETH_CUSTOM }

    public fun starcoin_mainnet(): u8 { ChainId::main() }

    public fun starcoin_testnet(): u8 { ChainId::test() }

    public fun starcoin_devnet(): u8 { ChainId::dev() }

    public fun starcoin_barnard(): u8 { ChainId::barnard() }


    public fun route_source(route: &BridgeRoute): &u8 {
        &route.source
    }

    public fun route_destination(route: &BridgeRoute): &u8 {
        &route.destination
    }

    public fun assert_valid_chain_id(id: u8) {
        assert!(
            id == ChainId::main() ||
                id == ChainId::barnard() ||
                id == ChainId::proxima() ||
                id == ChainId::halley() ||
                id == ChainId::dev() ||
                id == ChainId::test() ||
                id == ETH_MAINNET ||
                id == ETH_SEPOLIA ||
                id == ETH_CUSTOM,
            EInvalidBridgeRoute,
        )
    }

    public fun valid_routes(): vector<BridgeRoute> {
        vector[
            BridgeRoute { source: ChainId::main(), destination: ETH_MAINNET },
            BridgeRoute { source: ETH_MAINNET, destination: ChainId::main() },
            BridgeRoute { source: ChainId::proxima(), destination: ETH_SEPOLIA },
            BridgeRoute { source: ChainId::test(), destination: ETH_CUSTOM },
            BridgeRoute { source: ChainId::dev(), destination: ETH_CUSTOM },
            BridgeRoute { source: ChainId::dev(), destination: ETH_SEPOLIA },
            BridgeRoute { source: ETH_SEPOLIA, destination: ChainId::test() },
            BridgeRoute { source: ETH_SEPOLIA, destination: ChainId::test() },
            BridgeRoute { source: ETH_CUSTOM, destination: ChainId::dev() },
            BridgeRoute { source: ETH_CUSTOM, destination: ChainId::dev() },
        ]
    }

    public fun is_valid_route(source: u8, destination: u8): bool {
        let route = BridgeRoute { source, destination };
        Vector::contains(&valid_routes(), &route)
    }

    // Checks and return BridgeRoute if the route is supported by the bridge.
    public fun get_route(source: u8, destination: u8): BridgeRoute {
        let route = BridgeRoute { source, destination };
        assert!(Vector::contains(&valid_routes(), &route), Errors::invalid_state(EInvalidBridgeRoute));
        route
    }

    //////////////////////////////////////////////////////
    // Test functions
    //

    #[test]
    fun test_chains_ok() {
        assert_valid_chain_id(ChainId::main());
        assert_valid_chain_id(ChainId::test());
        assert_valid_chain_id(ChainId::dev());
        assert_valid_chain_id(ETH_MAINNET);
        assert_valid_chain_id(ETH_SEPOLIA);
        assert_valid_chain_id(ETH_CUSTOM);
    }

    #[test, expected_failure(abort_code = EInvalidBridgeRoute)]
    fun test_chains_error() {
        assert_valid_chain_id(100);
    }

    #[test, expected_failure(abort_code = EInvalidBridgeRoute)]
    fun test_sui_chains_error() {
        // this will break if we add one more sui chain id and should be corrected
        assert_valid_chain_id(4);
    }

    #[test, expected_failure(abort_code = EInvalidBridgeRoute)]
    fun test_eth_chains_error() {
        // this will break if we add one more eth chain id and should be corrected
        assert_valid_chain_id(13);
    }

    #[test]
    fun test_routes() {
        let valid_routes = vector[
            BridgeRoute { source: ChainId::main(), destination: ETH_MAINNET },
            BridgeRoute { source: ETH_MAINNET, destination: ChainId::main() },
            BridgeRoute { source: ChainId::test(), destination: ETH_SEPOLIA },
            BridgeRoute { source: ChainId::test(), destination: ETH_CUSTOM },
            BridgeRoute { source: ChainId::dev(), destination: ETH_CUSTOM },
            BridgeRoute { source: ChainId::dev(), destination: ETH_SEPOLIA },
            BridgeRoute { source: ETH_SEPOLIA, destination: ChainId::test() },
            BridgeRoute { source: ETH_SEPOLIA, destination: ChainId::dev() },
            BridgeRoute { source: ETH_CUSTOM, destination: ChainId::test() },
            BridgeRoute { source: ETH_CUSTOM, destination: ChainId::dev() },
        ];
        let size = Vector::length(&valid_routes);
        while (size > 0) {
            size = size - 1;
            let route = valid_routes[size];
            assert!(is_valid_route(route.source, route.destination)); // sould not assert
        }
    }

    #[test, expected_failure(abort_code = EInvalidBridgeRoute)]
    fun test_routes_err_sui_1() {
        get_route(ChainId::main(), ChainId::main());
    }

    #[test, expected_failure(abort_code = EInvalidBridgeRoute)]
    fun test_routes_err_sui_2() {
        get_route(ChainId::main(), ChainId::test());
    }

    #[test, expected_failure(abort_code = EInvalidBridgeRoute)]
    fun test_routes_err_sui_3() {
        get_route(ChainId::main(), ETH_SEPOLIA);
    }

    #[test, expected_failure(abort_code = EInvalidBridgeRoute)]
    fun test_routes_err_sui_4() {
        get_route(ChainId::main(), ETH_CUSTOM);
    }

    #[test, expected_failure(abort_code = EInvalidBridgeRoute)]
    fun test_routes_err_eth_1() {
        get_route(ETH_MAINNET, ETH_MAINNET);
    }

    #[test, expected_failure(abort_code = EInvalidBridgeRoute)]
    fun test_routes_err_eth_2() {
        get_route(ETH_MAINNET, ETH_CUSTOM);
    }

    #[test, expected_failure(abort_code = EInvalidBridgeRoute)]
    fun test_routes_err_eth_3() {
        get_route(ETH_MAINNET, ChainId::dev());
    }

    #[test, expected_failure(abort_code = EInvalidBridgeRoute)]
    fun test_routes_err_eth_4() {
        get_route(ETH_MAINNET, ChainId::test());
    }
}
