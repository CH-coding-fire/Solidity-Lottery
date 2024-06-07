// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    event EnteredRaffle(address indexed player);

    Raffle raffle;
    HelperConfig helperConfig;
    address public PLAYER = makeAddr("players");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant SEND_VALUE = 0.1 ether;
    uint256 public constant SEND_INSUFFICIENT_VALUE = 0.001 ether;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address linkAddress;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            linkAddress
        ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    ///
    //enterRaffle
    //

    function testRaffleRevertsWhenYouDontPayEnough() public {
        //Arrange
        vm.startPrank(PLAYER);
        //Act
        //Assert
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle{value: SEND_INSUFFICIENT_VALUE}();
        vm.stopPrank();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        //Arrange
        vm.startPrank(PLAYER);
        //Act
        raffle.enterRaffle{value: SEND_VALUE}();
        address payable[] memory players = raffle.getPlayers();
        assertEq(players[0], PLAYER);
    }

    function testEmitsEventOnEntrance() public {
        vm.startPrank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: SEND_VALUE}();
    }

    function testCantEnterWhenRaffleIsCalculating() public {
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: SEND_VALUE}();
        vm.stopPrank();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.startPrank(PLAYER);
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        raffle.enterRaffle{value: SEND_VALUE}();
        vm.stopPrank();
    }

    function testCheckUpkeepReturnsFalseIfIthasNoBalance() public {
        // Arrange

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public {
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: SEND_VALUE}();
        vm.stopPrank();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded == false);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: SEND_VALUE}();
        vm.stopPrank();
        vm.warp(block.timestamp + interval - 20);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded == false);
    }

    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public {
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: SEND_VALUE}();
        vm.stopPrank();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded == true);
    }

    function testPerformanUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: SEND_VALUE}();
        vm.stopPrank();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");
    }
}
