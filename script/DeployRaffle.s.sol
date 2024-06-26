    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.18;

import "../lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            address addressLink,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(
                vrfCoordinator,
                deployerKey
            );

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                vrfCoordinator,
                subscriptionId,
                addressLink,
                deployerKey
            );
        }

        vm.startBroadcast();

        Raffle raffle = new Raffle(
            entranceFee,
            interval,
            address(vrfCoordinator),
            gasLane,
            subscriptionId,
            callbackGasLimit,
            addressLink
        );
        vm.stopBroadcast();
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(raffle),
            vrfCoordinator,
            subscriptionId,
            deployerKey
        );
        return (raffle, helperConfig);
    }
    //a function that deploy to certain blockchain

    //first I must have the RPC to call the network, and the network will deploy
    //the contract into the chain, also to prove that I am the owner of public address
    //I am using to call the network, I must provide the private key
}
