// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {ConfirmedOwner} from "@chainlink/contracts@1.1.0/src/v0.8/shared/access/ConfirmedOwner.sol";
import {VRFV2WrapperConsumerBase} from "@chainlink/contracts@1.1.0/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";
import {LinkTokenInterface} from "@chainlink/contracts@1.1.0/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

struct ProbabilityItem {
    string name;
    uint256 p;
}

struct Rule {
    uint256 ruleId;
    address owner;
    ProbabilityItem[] lotteryProbabilities;
    uint256 createTime;
    bool available;
}

struct RequestStatus {
    uint256 paid; // amount paid in link
    bool fulfilled; // whether the request has been successfully fulfilled
    uint256[] randomWords;
    address user;
    uint256 ruleId;
    string reward;
}

contract Lottery is VRFV2WrapperConsumerBase, ConfirmedOwner {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );
    event RewardSelected(address user, uint256 requestId, string reward);

    uint256 nextRuleId = 1;
    mapping(uint256 => Rule) ruleset;
    mapping(address => uint256[]) owner2rules;

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public lastRequestId;

    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
    uint32 numWords = 1;

    // Address LINK - hardcoded for Sepolia
    address linkAddress = 0x779877A7B0D9E8603169DdbD7836e478b4624789;

    // address WRAPPER - hardcoded for Sepolia
    address wrapperAddress = 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46;

    constructor()
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {}

    /**
     * Callback function used by VRF Coordinator
     */
    // function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    //     randomResult = randomness % 100;
    //     // Use the random number to select a reward
    //     Rule storage rule = ruleset[requestToRuleId[requestId]];
    //     string memory reward = this.select(rule.lotteryProbabilities);
    //     // Do something with the reward, e.g., emit an event
    //     emit RewardSelected(requestId, reward);
    // }

    function createRule(
        string[] memory rewardNames,
        uint256[] memory rewardProbabilitis
    ) public returns (uint256) {
        require(rewardNames.length == rewardProbabilitis.length);
        uint256 totalProbability = 0;

        for (uint256 i = 0; i < rewardProbabilitis.length; i++) {
            totalProbability += rewardProbabilitis[i];
        }

        require(
            totalProbability == 100,
            "The total probability should be 100!"
        );

        uint256 ruleId = nextRuleId++;
        ruleset[ruleId].ruleId = ruleId;
        ruleset[ruleId].owner = msg.sender;
        ruleset[ruleId].createTime = block.timestamp;
        ruleset[ruleId].available = true;

        for (uint256 i = 0; i < rewardProbabilitis.length; i++) {
            ProbabilityItem memory newItem = ProbabilityItem(
                rewardNames[i],
                rewardProbabilitis[i]
            );
            ruleset[ruleId].lotteryProbabilities.push(newItem);
        }

        owner2rules[msg.sender].push(ruleId);
        return ruleId;
    }

    function getRules() public view returns (uint256[] memory) {
        return owner2rules[msg.sender];
    }

    function getRule(uint256 ruleId) public view returns (Rule memory) {
        return ruleset[ruleId];
    }

    function select(uint256 randomResult, ProbabilityItem[] memory probabilities)
        external
        pure
        returns (string memory)
    {
        uint256 sum = 0;
        for (uint256 i = 0; i < probabilities.length; i++) {
            sum += probabilities[i].p;
            if (randomResult < sum) {
                return probabilities[i].name;
            }
        }

        return "";
    }

    // function getReward(uint256 ruleId) public returns (bytes32) {
    //     uint256 requestId = requestRandomness(keyHash, fee);
    //     return requestId;
    // }


    function getReward(uint256 ruleId)
        external
        onlyOwner
        returns (uint256 requestId)
    {
        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWords: new uint256[](0),
            fulfilled: false,
            user: msg.sender,
            ruleId: ruleId,
            reward: ""
        });
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].paid > 0, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );

        uint256 randomResult = _randomWords[0] % 100;
        // Use the random number to select a reward
        Rule storage rule = ruleset[s_requests[_requestId].ruleId];
        string memory reward = this.select(randomResult, rule.lotteryProbabilities);

        emit RewardSelected(s_requests[_requestId].user, _requestId, reward);
    }

    function getRequestStatus(
        uint256 _requestId
    )
        external
        view
        returns (uint256 paid, bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].paid > 0, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    fallback() external {
        revert("something wrong");
    }
}

// ["Phone", "Laptop", "Mouse", "Nothing, Damn!"]
// [20, 10, 30, 40]
