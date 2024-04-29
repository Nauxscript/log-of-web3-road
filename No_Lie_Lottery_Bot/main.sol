// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts@1.1.0/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts@1.1.0/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {ConfirmedOwner} from "@chainlink/contracts@1.1.0/src/v0.8/shared/access/ConfirmedOwner.sol";

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
    bool fulfilled; // whether the request has been successfully fulfilled
    bool exists; // whether a requestId exists
    uint256[] randomWords;
    address user;
    uint256 ruleId;
    string reward;
}

contract Lottery is VRFConsumerBaseV2, ConfirmedOwner {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords
    );
    event RewardSelected(address user, uint256 requestId, string reward);

    uint256 nextRuleId = 1;
    mapping(uint256 => Rule) ruleset;
    mapping(address => uint256[]) owner2rules;

    bytes32 keyHash =
        0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint256 internal fee;

    uint256 public lastRequestId;

    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    // Your subscription ID.
    uint64 s_subscriptionId;

    uint32 callbackGasLimit = 200000;

    VRFCoordinatorV2Interface COORDINATOR;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
    uint32 numWords = 1;

    // address WRAPPER - hardcoded for Sepolia
    address wrapperAddress = 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46;

    constructor(
        uint64 subscriptionId
    )
        VRFConsumerBaseV2(0xab18414CD93297B0d12ac29E63Ca20f515b3DB46)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0xab18414CD93297B0d12ac29E63Ca20f515b3DB46
        );
        s_subscriptionId = subscriptionId;
    }

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
            if (bytes(rewardNames[i]).length == 0) {
                revert("Reward cannot be empty");
            }
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

    function getReward(uint256 ruleId)
        external
        onlyOwner
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false,
            user: msg.sender,
            ruleId: ruleId,
            reward: ""
        });
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords()
        external
        onlyOwner
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false,
            user: msg.sender,
            ruleId: 0,
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
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(
            _requestId,
            _randomWords
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
        returns (bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    fallback() external {
        revert("something wrong");
    }
}

// ["Phone", "Laptop", "Mouse", "Nothing, Damn!"]
// [20, 10, 30, 40]
