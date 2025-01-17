// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Chainlink VRF Interface
interface VRFCoordinatorV2Interface {
    function requestRandomWords(
        uint64 subscriptionId,
        address requester,
        uint32 numWords,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        uint32 numBlockConfirmations
    ) external returns (uint256 requestId);
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Lottery {
    event LotteryStarted(uint256 maxTickets, uint256 ticketPrice);
    event TicketPurchased(address indexed player, uint256 ticketCount);
    event WinnerPicked(address indexed winner, uint256 amountWon);
    event LotteryPaused();
    event LotteryUnpaused();
    event RandomnessRequested(uint256 requestId);
    event RandomnessFulfilled(uint256 requestId, uint256 randomNumber);

    address private _owner;
    address[] private players;
    address public latestWinner;
    uint256 public ticketPrice;
    uint256 public maxTickets;
    bool public isOpen;
    bool public paused;

    uint256 public lastDrawTimestamp;
    uint256 public drawInterval = 1 days;

    // Chainlink VRF
    VRFCoordinatorV2Interface private vrfCoordinator;
    uint64 private vrfSubscriptionId;
    uint32 private callbackGasLimit = 500000;
    uint16 private requestConfirmations = 3;
    uint32 private numRandomWords = 1;
    uint32 private numBlockConfirmations = 3; // Added block confirmations parameter
    uint256 private currentRequestId;

    // Custom ERC-20 token for betting
    IERC20 public customToken;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    constructor(address _vrfCoordinator, uint64 _vrfSubscriptionId, address _customToken) {
        _owner = msg.sender;
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        vrfSubscriptionId = _vrfSubscriptionId;
        customToken = IERC20(_customToken);
    }

    function startLottery(uint256 _maxTickets, uint256 _ticketPrice)
        public
        onlyOwner
        whenNotPaused
    {
        require(!isOpen, "Lottery is already open");
        maxTickets = _maxTickets;
        ticketPrice = _ticketPrice;
        isOpen = true;
        players = new address[](0);
        lastDrawTimestamp = block.timestamp;
        emit LotteryStarted(maxTickets, ticketPrice);
    }

    function enter(uint256 _ticketCount) public whenNotPaused {
        require(isOpen, "Lottery is not open");
        require(_ticketCount > 0, "Must purchase at least 1 ticket");
        uint256 totalCost = _ticketCount * ticketPrice;
        require(customToken.balanceOf(msg.sender) >= totalCost, "Insufficient token balance");
        
        customToken.transferFrom(msg.sender, address(this), totalCost);

        for (uint256 i = 0; i < _ticketCount; i++) {
            players.push(msg.sender);
        }
        emit TicketPurchased(msg.sender, _ticketCount);
    }

    function requestRandomNumber() private {
        currentRequestId = vrfCoordinator.requestRandomWords(
            vrfSubscriptionId,
            address(this),
            numRandomWords,
            requestConfirmations,
            callbackGasLimit,
            numBlockConfirmations  // Added the missing parameter
        );
        emit RandomnessRequested(currentRequestId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
        require(msg.sender == address(vrfCoordinator), "Only VRF Coordinator can fulfill");

        // Ensure the requestId matches
        require(requestId == currentRequestId, "Request ID mismatch");

        uint256 randomNumber = randomWords[0];
        emit RandomnessFulfilled(requestId, randomNumber);

        // Pick winner using randomness
        uint256 winnerIndex = randomNumber % players.length;
        address winner = players[winnerIndex];
        uint256 prizeAmount = address(this).balance;

        (bool success, ) = winner.call{value: prizeAmount}("");
        require(success, "Transfer to winner failed");

        latestWinner = winner;
        isOpen = false;

        emit WinnerPicked(winner, prizeAmount);
    }

    function autoDrawWinner() public {
        require(isOpen, "Lottery is not open");
        require(block.timestamp >= lastDrawTimestamp + drawInterval, "Too early for next draw");

        lastDrawTimestamp = block.timestamp;
        requestRandomNumber();
    }

    function pauseLottery() public onlyOwner {
        paused = true;
        emit LotteryPaused();
    }

    function unpauseLottery() public onlyOwner {
        paused = false;
        emit LotteryUnpaused();
    }

    function withdraw() public onlyOwner {
        require(!isOpen, "Cannot withdraw while lottery is open");
        uint256 balance = address(this).balance;
        (bool success, ) = _owner.call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _owner = newOwner;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function setDrawInterval(uint256 _interval) public onlyOwner {
        drawInterval = _interval;
    }

    // For receiving Ether when prize is distributed
    receive() external payable {}
}
