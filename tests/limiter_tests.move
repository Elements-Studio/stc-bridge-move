// // Copyright (c) Mysten Labs, Inc.
// // SPDX-License-Identifier: Apache-2.0
//
// #[test_only]
// module bridge::limiter_tests;
//
// use bridge::chain_ids;
// use bridge::limiter::{
//     check_and_record_sending_transfer,
//     make_transfer_limiter,
//     max_transfer_limit,
//     new,
//     transfer_limits_mut,
//     total_amount,
//     transfer_records,
//     update_route_limit,
//     usd_value_multiplier
// };
// use bridge::treasury::{Self, BTC, ETH, USDC, USDT};
// use std::unit_test::assert;
// use sui::clock;
// use sui::test_scenario;
// use sui::test_utils::destroy;
//
// #[test]
// fun test_24_hours_windows() {
//     let mut limiter = make_transfer_limiter();
//
//     let route = ChainIDs::get_route(ChainIDs::sui_custom(), ChainIDs::eth_sepolia());
//
//     let mut scenario = test_scenario::begin(@0x1);
//     let ctx = test_scenario::ctx(&mut scenario);
//     let mut treasury = treasury::mock_for_test(ctx);
//
//     // Global transfer limit is 100M USD
//     transfer_limits_mut(&limiter).insert(route, 100_000_000 * usd_value_multiplier());
//     // Notional price for ETH is 5 USD
//     let id = treasury::token_id<ETH>(&treasury);
//     update_asset_notional_price(&treasury)id, 5 * usd_value_multiplier());
//
//     let mut clock = clock::create_for_testing(ctx);
//     set_for_testing(&clock)1706288001377);
//
//     // transfer 10000 ETH every hour, the totol should be 10000 * 5
//     assert!(
//         check_and_record_sending_transfer<ETH>(&limiter)
//             &treasury,
//             &clock,
//             route,
//             10_000 * decimal_multiplier<ETH>(&treasury),
//         ),
//         0,
//     );
//
//     let record = transfer_records(&limiter).get(&route);
//     assert!(total_amount(&record) == 10000 * 5 * usd_value_multiplier());
//
//     // transfer 1000 ETH every hour for 50 hours, the 24 hours totol should be 24000 * 10
//     let mut i = 0;
//     while (i < 50) {
//         increment_for_testing(&clock)60 * 60 * 1000);
//         assert!(
//             check_and_record_sending_transfer<ETH>(&limiter)
//                 &treasury,
//                 &clock,
//                 route,
//                 1_000 * decimal_multiplier<ETH>(&treasury),
//             ),
//             0,
//         );
//         i = i + 1;
//     };
//     let record = transfer_records(&limiter).get(&route);
//     let mut expected_value = 24000 * 5 * usd_value_multiplier();
//     assert!(total_amount(&record), expected_value);
//
//     // transfer 1000 * i ETH every hour for 24 hours, the 24 hours
//     // totol should be 300 * 1000 * 5
//     let mut i = 0;
//     // At this point, every hour in past 24 hour has value $5000.
//     // In each iteration, the old $5000 gets replaced with (i * 5000)
//     while (i < 24) {
//         increment_for_testing(&clock)60 * 60 * 1000);
//         assert!(
//             check_and_record_sending_transfer<ETH>(&limiter)
//                 &treasury,
//                 &clock,
//                 route,
//                 1_000 * decimal_multiplier<ETH>(&treasury) * (i + 1),
//             ),
//             0,
//         );
//
//         let record = transfer_records(&limiter).get(&route);
//
//         expected_value = expected_value + 1000 * 5 * i * usd_value_multiplier();
//         assert!(total_amount(&record), expected_value);
//         i = i + 1;
//     };
//
//     let record = transfer_records(&limiter).get(&route);
//     assert!(total_amount(&record), 300 * 1000 * 5 * usd_value_multiplier());
//
//     destroy(limiter);
//     destroy(treasury);
//     clock::destroy_for_testing(clock);
//     test_scenario::end(scenario);
// }
//
// #[test]
// fun test_24_hours_windows_multiple_route() {
//     let mut limiter = make_transfer_limiter();
//
//     let route = ChainIDs::get_route(ChainIDs::sui_custom(), ChainIDs::eth_sepolia());
//     let route2 = ChainIDs::get_route(ChainIDs::eth_sepolia(), ChainIDs::sui_custom());
//
//     let mut scenario = test_scenario::begin(@0x1);
//     let ctx = test_scenario::ctx(&mut scenario);
//     let mut treasury = treasury::mock_for_test(ctx);
//
//     // Global transfer limit is 1M USD
//     transfer_limits_mut(&limiter).insert(route, 1_000_000 * usd_value_multiplier());
//     transfer_limits_mut(&limiter).insert(route2, 500_000 * usd_value_multiplier());
//     // Notional price for ETH is 5 USD
//     let id = treasury::token_id<ETH>(&treasury);
//     update_asset_notional_price(&treasury)id, 5 * usd_value_multiplier());
//
//     let mut clock = clock::create_for_testing(ctx);
//     set_for_testing(&clock)1706288001377);
//
//     // Transfer 10000 ETH on route 1
//     assert!(
//         check_and_record_sending_transfer<ETH>(&limiter)
//             &treasury,
//             &clock,
//             route,
//             10_000 * treasury::decimal_multiplier<ETH>(&treasury),
//         ),
//         0,
//     );
//     // Transfer 50000 ETH on route 2
//     assert!(
//         check_and_record_sending_transfer<ETH>(&limiter)
//             &treasury,
//             &clock,
//             route2,
//             50_000 * treasury::decimal_multiplier<ETH>(&treasury),
//         ),
//         0,
//     );
//
//     let record = transfer_records(&limiter).get(&route);
//     assert!(total_amount(&record) == 10000 * 5 * usd_value_multiplier());
//
//     let record = transfer_records(&limiter).get(&route2);
//     assert!(total_amount(&record) == 50000 * 5 * usd_value_multiplier());
//
//     destroy(limiter);
//     destroy(treasury);
//     clock::destroy_for_testing(clock);
//     test_scenario::end(scenario);
// }
//
// #[test]
// fun test_exceed_limit() {
//     let mut limiter = make_transfer_limiter();
//
//     let mut scenario = test_scenario::begin(@0x1);
//     let ctx = test_scenario::ctx(&mut scenario);
//     let mut treasury = treasury::mock_for_test(ctx);
//
//     let route = ChainIDs::get_route(ChainIDs::sui_custom(), ChainIDs::eth_sepolia());
//     // Global transfer limit is 1M USD
//     transfer_limits_mut(&limiter).insert(route, 1_000_000 * usd_value_multiplier());
//     // Notional price for ETH is 10 USD
//     let id = treasury::token_id<ETH>(&treasury);
//     update_asset_notional_price(&treasury)id, 10 * usd_value_multiplier());
//
//     let mut clock = clock::create_for_testing(ctx);
//     set_for_testing(&clock)1706288001377);
//
//     assert!(
//         check_and_record_sending_transfer<ETH>(&limiter)
//             &treasury,
//             &clock,
//             route,
//             90_000 * treasury::decimal_multiplier<ETH>(&treasury),
//         ),
//         0,
//     );
//
//     let record = transfer_records(&limiter).get(&route);
//     assert!(total_amount(&record), 90000 * 10 * usd_value_multiplier());
//
//     increment_for_testing(&clock)60 * 60 * 1000);
//     assert!(
//         check_and_record_sending_transfer<ETH>(&limiter)
//             &treasury,
//             &clock,
//             route,
//             10_000 * treasury::decimal_multiplier<ETH>(&treasury),
//         ),
//         0,
//     );
//     let record = transfer_records(&limiter).get(&route);
//     assert!(total_amount(&record), 100000 * 10 * usd_value_multiplier());
//
//     // Tx should fail with a tiny amount because the limit is hit
//     assert!(!check_and_record_sending_transfer<ETH>(&limiter)&treasury, &clock, route, 1), 0);
//     assert!(
//         !check_and_record_sending_transfer<ETH>(&limiter)
//             &treasury,
//             &clock,
//             route,
//             90_000 * treasury::decimal_multiplier<ETH>(&treasury),
//         ),
//         0,
//     );
//
//     // Fast forward 23 hours, now the first 90k should be discarded
//     increment_for_testing(&clock)60 * 60 * 1000 * 23);
//     assert!(
//         check_and_record_sending_transfer<ETH>(&limiter)
//             &treasury,
//             &clock,
//             route,
//             90_000 * treasury::decimal_multiplier<ETH>(&treasury),
//         ),
//         0,
//     );
//     let record = transfer_records(&limiter).get(&route);
//     assert!(total_amount(&record), 100000 * 10 * usd_value_multiplier());
//
//     // But now limit is hit again
//     assert!(!check_and_record_sending_transfer<ETH>(&limiter)&treasury, &clock, route, 1), 0);
//     let record = transfer_records(&limiter).get(&route);
//     assert!(total_amount(&record), 100000 * 10 * usd_value_multiplier());
//
//     destroy(limiter);
//     destroy(treasury);
//     clock::destroy_for_testing(clock);
//     test_scenario::end(scenario);
// }
//
// #[test, expected_failure(abort_code = bridge::limiter::ELimitNotFoundForRoute)]
// fun test_limiter_does_not_limit_receiving_transfers() {
//     let mut limiter = new();
//
//     let route = ChainIDs::get_route(ChainIDs::sui_mainnet(), ChainIDs::eth_mainnet());
//     let mut scenario = test_scenario::begin(@0x1);
//     let ctx = ctx(&scenario);
//     let treasury = treasury::mock_for_test(ctx);
//     let mut clock = clock::create_for_testing(ctx);
//     set_for_testing(&clock)1706288001377);
//     // We don't limit sui -> eth transfers. This aborts with `ELimitNotFoundForRoute`
//     check_and_record_sending_transfer<ETH>(&limiter)
//         &treasury,
//         &clock,
//         route,
//         1 * treasury::decimal_multiplier<ETH>(&treasury),
//     );
//     destroy(limiter);
//     destroy(treasury);
//     clock::destroy_for_testing(clock);
//     test_scenario::end(scenario);
// }
//
// #[test]
// fun test_limiter_basic_op() {
//     // In this test we use very simple number for easier calculation.
//     let mut limiter = make_transfer_limiter();
//
//     let mut scenario = test_scenario::begin(@0x1);
//     let ctx = test_scenario::ctx(&mut scenario);
//     let mut treasury = treasury::mock_for_test(ctx);
//
//     let route = ChainIDs::get_route(ChainIDs::eth_sepolia(), ChainIDs::starcoin_testnet());
//     // Global transfer limit is 100 USD
//     transfer_limits_mut(&limiter).insert(route, 100 * usd_value_multiplier());
//     // BTC: $10, ETH: $2.5, USDC: $1, USDT: $0.5
//     let id = treasury::token_id<BTC>(&treasury);
//     update_asset_notional_price(&treasury)id, 10 * usd_value_multiplier());
//     let id = treasury::token_id<ETH>(&treasury);
//     let eth_price = 250000000;
//     update_asset_notional_price(&treasury)id, eth_price);
//     let id = treasury::token_id<USDC>(&treasury);
//     update_asset_notional_price(&treasury)id, 1 * usd_value_multiplier());
//     let id = treasury::token_id<USDT>(&treasury);
//     update_asset_notional_price(&treasury)id, 50000000);
//
//     let mut clock = clock::create_for_testing(ctx);
//     set_for_testing(&clock)36082800000); // hour 10023
//
//     // hour 0 (10023): $15 * 2.5 = $37.5
//     // 15 eth = $37.5
//     assert!(
//         check_and_record_sending_transfer<ETH>(&limiter)
//             &treasury,
//             &clock,
//             route,
//             15 * treasury::decimal_multiplier<ETH>(&treasury),
//         ),
//         0,
//     );
//     let record = transfer_records(&limiter).get(&route);
//     assert!(hour_head(&record), 10023);
//     assert!(hour_tail(&record), 10000);
//     assert!(
//         per_hour_amounts(&record) ==
//             &vector[
//                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
//                 15 * eth_price,
//             ],
//         0,
//     );
//     assert!(total_amount(&record), 15 * eth_price);
//
//     // hour 0 (10023): $37.5 + $10 = $47.5
//     // 10 uddc = $10
//     assert!(
//         check_and_record_sending_transfer<USDC>(&limiter)
//             &treasury,
//             &clock,
//             route,
//             10 * treasury::decimal_multiplier<USDC>(&treasury),
//         ),
//         0,
//     );
//     let record = transfer_records(&limiter).get(&route);
//     assert!(hour_head(&record), 10023);
//     assert!(hour_tail(&record), 10000);
//     let expected_notion_amount_10023 = 15 * eth_price + 10 * usd_value_multiplier();
//     assert!(
//         per_hour_amounts(&record) ==
//             &vector[
//                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
//                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
//                 expected_notion_amount_10023,
//             ],
//         0,
//     );
//     assert!(total_amount(&record), expected_notion_amount_10023);
//
//     // hour 1 (10024): $20
//     increment_for_testing(&clock)60 * 60 * 1000);
//     // 2 btc = $20
//     assert!(
//         check_and_record_sending_transfer<BTC>(&limiter)
//             &treasury,
//             &clock,
//             route,
//             2 * treasury::decimal_multiplier<BTC>(&treasury),
//         ),
//         0,
//     );
//     let record = transfer_records(&limiter).get(&route);
//     assert!(hour_head(&record), 10024);
//     assert!(hour_tail(&record), 10001);
//     let expected_notion_amount_10024 = 20 * usd_value_multiplier();
//     assert!(
//         per_hour_amounts(&record) ==
//             &vector[
//                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
//                 expected_notion_amount_10023,
//                 expected_notion_amount_10024,
//             ],
//         0,
//     );
//     assert!(total_amount(&record), expected_notion_amount_10023 + expected_notion_amount_10024);
//
//     // Fast forward 22 hours, now hour 23 (10046): try to transfer $33 willf fail
//     increment_for_testing(&clock)60 * 60 * 1000 * 22);
//     // fail
//     // 65 usdt = $33
//     assert!(
//         !check_and_record_sending_transfer<USDT>(&limiter)
//             &treasury,
//             &clock,
//             route,
//             66 * 1_000_000,
//         ),
//         0,
//     );
//     // but window slid
//     let record = transfer_records(&limiter).get(&route);
//     assert!(hour_head(&record), 10046);
//     assert!(hour_tail(&record), 10023);
//     assert!(
//         per_hour_amounts(&record) ==
//             &vector[
//                 expected_notion_amount_10023, expected_notion_amount_10024,
//                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
//             ],
//         0,
//     );
//     assert!(total_amount(&record), expected_notion_amount_10023 + expected_notion_amount_10024);
//
//     // hour 23 (10046): $32.5 deposit will succeed
//     // 65 usdt = $32.5
//     assert!(
//         check_and_record_sending_transfer<USDT>(&limiter)
//             &treasury,
//             &clock,
//             route,
//             65 * 1_000_000,
//         ),
//         0,
//     );
//     let record = transfer_records(&limiter).get(&route);
//     let expected_notion_amount_10046 = 325 * usd_value_multiplier() / 10;
//     assert!(hour_head(&record), 10046);
//     assert!(hour_tail(&record), 10023);
//     assert!(
//         per_hour_amounts(&record) ==
//             &vector[
//                 expected_notion_amount_10023,
//                 expected_notion_amount_10024,
//                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
//                 expected_notion_amount_10046,
//             ],
//         0,
//     );
//     assert!(
//         total_amount(&record),
//         expected_notion_amount_10023 + expected_notion_amount_10024 + expected_notion_amount_10046,
//     );
//
//     // Hour 24 (10047), we can deposit $0.5 now
//     increment_for_testing(&clock)60 * 60 * 1000);
//     // 1 usdt = $0.5
//     assert!(
//         check_and_record_sending_transfer<USDT>(&limiter)&treasury, &clock, route, 1_000_000),
//         0,
//     );
//     let record = transfer_records(&limiter).get(&route);
//     let expected_notion_amount_10047 = 5 * usd_value_multiplier() / 10;
//     assert!(hour_head(&record), 10047);
//     assert!(hour_tail(&record), 10024);
//     assert!(
//         per_hour_amounts(&record) ==
//             &vector[
//                 expected_notion_amount_10024,
//                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
//                 expected_notion_amount_10046,
//                 expected_notion_amount_10047,
//             ],
//         0,
//     );
//     assert!(
//         total_amount(&record),
//         expected_notion_amount_10024 + expected_notion_amount_10046 + expected_notion_amount_10047,
//     );
//
//     // Fast forward to Hour 30 (10053)
//     increment_for_testing(&clock)60 * 60 * 1000 * 6);
//     // 1 usdc = $1
//     assert!(
//         check_and_record_sending_transfer<USDC>(&limiter)
//             &treasury,
//             &clock,
//             route,
//             1 * treasury::decimal_multiplier<USDC>(&treasury),
//         ),
//         0,
//     );
//     let record = transfer_records(&limiter).get(&route);
//     let expected_notion_amount_10053 = 1 * usd_value_multiplier();
//     assert!(hour_head(&record), 10053);
//     assert!(hour_tail(&record), 10030);
//     assert!(
//         per_hour_amounts(&record) ==
//             &vector[
//                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
//                 expected_notion_amount_10046,
//                 expected_notion_amount_10047,
//                 0, 0, 0, 0, 0,
//                 expected_notion_amount_10053,
//             ],
//         0,
//     );
//     assert!(
//         total_amount(&record),
//         expected_notion_amount_10046 + expected_notion_amount_10047 + expected_notion_amount_10053,
//     );
//
//     // Fast forward to hour 130 (10153)
//     increment_for_testing(&clock)60 * 60 * 1000 * 100);
//     // 1 usdc = $1
//     assert!(
//         check_and_record_sending_transfer<USDC>(&limiter)
//             &treasury,
//             &clock,
//             route,
//             treasury::decimal_multiplier<USDC>(&treasury),
//         ),
//         0,
//     );
//     let record = transfer_records(&limiter).get(&route);
//     let expected_notion_amount_10153 = 1 * usd_value_multiplier();
//     assert!(hour_head(&record), 10153);
//     assert!(hour_tail(&record), 10130);
//     assert!(
//         per_hour_amounts(&record) ==
//             &vector[
//                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
//                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
//                 expected_notion_amount_10153,
//             ],
//         0,
//     );
//     assert!(total_amount(&record), expected_notion_amount_10153);
//
//     destroy(limiter);
//     destroy(treasury);
//     clock::destroy_for_testing(clock);
//     test_scenario::end(scenario);
// }
//
// #[test]
// fun test_update_route_limit() {
//     // default routes, default notion values
//     let mut limiter = new();
//     assert!(
//         transfer_limits(&limiter)[
//             &ChainIDs::get_route(ChainIDs::eth_mainnet(), ChainIDs::sui_mainnet()),
//         ],
//         5_000_000 * usd_value_multiplier(),
//     );
//
//     assert!(
//         transfer_limits(&limiter)[
//             &ChainIDs::get_route(ChainIDs::eth_sepolia(), ChainIDs::starcoin_testnet()),
//         ],
//         max_transfer_limit(),
//     );
//
//     // shrink testnet limit
//     update_route_limit(
//         &mut limiter,
//         &ChainIDs::get_route(ChainIDs::eth_sepolia(), ChainIDs::starcoin_testnet()),
//         1_000 * usd_value_multiplier(),
//     );
//     assert!(
//         transfer_limits(&limiter)[
//             &ChainIDs::get_route(ChainIDs::eth_sepolia(), ChainIDs::starcoin_testnet()),
//         ],
//         1_000 * usd_value_multiplier(),
//     );
//     // mainnet route does not change
//     assert!(
//         transfer_limits(&limiter)[
//             &ChainIDs::get_route(ChainIDs::eth_mainnet(), ChainIDs::sui_mainnet()),
//         ],
//         5_000_000 * usd_value_multiplier(),
//     );
//     destroy(limiter);
// }
//
// #[test]
// fun test_update_route_limit_all_paths() {
//     let mut limiter = new();
//     // pick an existing route limit
//     assert!(
//         transfer_limits(&limiter)[
//             &ChainIDs::get_route(ChainIDs::eth_sepolia(), ChainIDs::starcoin_testnet()),
//         ],
//         max_transfer_limit(),
//     );
//     let new_limit = 1_000 * usd_value_multiplier();
//     update_route_limit(
//         &mut limiter,
//         &ChainIDs::get_route(ChainIDs::eth_sepolia(), ChainIDs::starcoin_testnet()),
//         new_limit,
//     );
//     assert!(
//         transfer_limits(&limiter)[
//             &ChainIDs::get_route(ChainIDs::eth_sepolia(), ChainIDs::starcoin_testnet()),
//         ],
//         new_limit,
//     );
//
//     // pick a new route limit
//     update_route_limit(
//         &mut limiter,
//         &ChainIDs::get_route(ChainIDs::starcoin_testnet(), ChainIDs::eth_sepolia()),
//         new_limit,
//     );
//     assert!(
//         transfer_limits(&limiter)[
//             &ChainIDs::get_route(ChainIDs::eth_sepolia(), ChainIDs::starcoin_testnet()),
//         ],
//         new_limit,
//     );
//
//     destroy(limiter);
// }
//
// #[test]
// fun test_update_asset_price() {
//     // default routes, default notion values
//     let mut scenario = test_scenario::begin(@0x1);
//     let ctx = test_scenario::ctx(&mut scenario);
//     let mut treasury = treasury::mock_for_test(ctx);
//
//     assert!(notional_value<BTC>(&treasury), (50_000 * usd_value_multiplier()));
//     assert!(notional_value<ETH>(&treasury), (3_000 * usd_value_multiplier()));
//     assert!(notional_value<USDC>(&treasury), (1 * usd_value_multiplier()));
//     assert!(notional_value<USDT>(&treasury), (1 * usd_value_multiplier()));
//     // change usdt price
//     let id = token_id<USDT>(&treasury);
//     update_asset_notional_price(&treasury)id, 11 * usd_value_multiplier() / 10);
//     assert!(notional_value<USDT>(&treasury), (11 * usd_value_multiplier() / 10));
//     // other prices do not change
//     assert!(notional_value<BTC>(&treasury), (50_000 * usd_value_multiplier()));
//     assert!(notional_value<ETH>(&treasury), (3_000 * usd_value_multiplier()));
//     assert!(notional_value<USDC>(&treasury), (1 * usd_value_multiplier()));
//     end(&scenario);
//     destroy(treasury);
// }
