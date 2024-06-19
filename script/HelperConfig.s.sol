// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/linkToken.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        uint256 deployerKey;
        address[] whateverArray;
        //rpc?
        //private key?
    }

    uint256 private DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            // activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        address[] memory hardcodedOwnerAddresses = new address[](3);
        hardcodedOwnerAddresses[0] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        hardcodedOwnerAddresses[1] = 0xA70E68936d0B7FC8512C50107a3A3bf396a32B24;
        hardcodedOwnerAddresses[2] = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30,
                vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
                gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 1893,
                callbackGasLimit: 500000,
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                deployerKey: vm.envUint("PRIVATE_KEY"),
                whateverArray:hardcodedOwnerAddresses
            });
    }

    // function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
    //     if (address(activeNetworkConfig.vrfCoordinator) != address(0)) {
    //         return activeNetworkConfig;
    //     }

    //     uint96 baseFee = 0.25 ether; //0.25 LINK
    //     uint96 gasPriceLink = 1e9; //1 gwei LINK

    //     vm.startBroadcast();
    //     VRFCoordinatorV2Mock vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(
    //         baseFee,
    //         gasPriceLink
    //     );
    //     LinkToken link = new LinkToken();
    //     vm.stopBroadcast();

    //     return
    //         NetworkConfig({
    //             entranceFee: 0.01 ether,
    //             interval: 30,
    //             vrfCoordinator: address(vrfCoordinatorV2Mock),
    //             gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, //does not matter
    //             subscriptionId: 0, //our script will add this!
    //             callbackGasLimit: 500000,
    //             link: address(link),
    //             deployerKey: DEFAULT_ANVIL_KEY
    //         });
    // }
}
