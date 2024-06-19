// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";


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
            linkAddress,
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

    // function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
    //     vm.startPrank(PLAYER);
    //     raffle.enterRaffle{value: SEND_VALUE}();
    //     vm.stopPrank();
    //     vm.warp(block.timestamp + interval - 20);
    //     vm.roll(block.number + 1);

    //     vm.expectRevert(abi.encodeWithSelector(
    //         Raffle.Raffle__UpkeepNotNeeded.selector,
    //          0, 0, 0)
    //          );
    //     raffle.performUpkeep("");
    // }

    modifier raffleEnteredAndTimePassed(){
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipFork() {
        if(block.chainid != 31337){ // this is avail chainid
            return;
        }
        _;
    }

    function testPerformUpkeepUpdateRaffleStateAndEmitsRequestId() 
    public
    raffleEnteredAndTimePassed
    {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1]; //0 topic refer to this 
        assert(uint256(requestId)>0);
        assert(uint256(raffle.getRaffleState())==1);
    }

    // What if I need to test using the output of an event

    function testFullfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep (
        uint256 randomRequestId //this is a random number autoly... fuzz test
    )
     public 
     raffleEnteredAndTimePassed 
     skipFork
     {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney()
    public
    raffleEnteredAndTimePassed
    {
        uint256 additionaEntrant = 5;
        uint256 startingIndex = 1;
        for(
            uint256 i = startingIndex;
            i < additionaEntrant+ startingIndex;
            i++
        ){
            address player = address(uint160(i));
            hoax(player, STARTING_USER_BALANCE);
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 prize = entranceFee * (additionaEntrant+1);

        vm.recordLogs();
        raffle.performUpkeep("");

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1]; //0 topic refer to this 

        console.log("requestId", uint256(requestId));

        uint256 previousTimeStamp = raffle.getLastTimeStamp();

        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );
        // assert(uint256(raffle.getRaffleState())==0);
        // assert(raffle.getRecentWinner() != address(0));
        // assert(raffle.getLengthOfPlayers() ==0 );
        // assert(previousTimeStamp < raffle.getLastTimeStamp());
        console.log(raffle.getRecentWinner().balance );
        console.log(STARTING_USER_BALANCE + prize - entranceFee);
        assert(raffle.getRecentWinner().balance == (STARTING_USER_BALANCE + prize - entranceFee));


        // assert(uint256(requestId)>0);
        // assert(uint256(raffle.getRaffleState())==1);

        //pretend to be chainlink vrf to get random number

    }


}


