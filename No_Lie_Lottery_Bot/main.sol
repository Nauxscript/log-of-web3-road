// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

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

contract Lottery is VRFConsumerBase {

  uint256 nextRuleId = 1;
  mapping (uint256 => Rule) ruleset;
  mapping (address => uint256[]) owner2rules;

  bytes32 internal keyHash;
  uint256 internal fee;
  uint256 private randomResult;

  mapping(bytes32 => uint256) requestToRuleId;

  constructor() 
        VRFConsumerBase(
            0xf720CF1B963e0e7bE9F58fd471EFa67e7bF00cfb, // VRF Coordinator
            0x20fE562d797A42Dcb3399062AE9546cd06f63280  // LINK Token
        )
    {
        keyHash = 0xced103054e349b8dfb51352f0f8fa9b5d20dde3d06f9f43cb2b85bc64b238205;
        fee = 0.1 * 10 ** 18; // 0.1 LINK
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness % 100;
        // Use the random number to select a reward
        Rule storage rule = ruleset[requestToRuleId[requestId]];
        string memory reward = this.select(rule.lotteryProbabilities);
        // Do something with the reward, e.g., emit an event
        emit RewardSelected(requestId, reward);
    }

  function createRule(string[] memory rewardNames, uint256[] memory rewardProbabilitis) public returns(uint256) {
    require(rewardNames.length == rewardProbabilitis.length);
    uint256 totalProbability = 0;

    for (uint256 i = 0; i < rewardProbabilitis.length; i++) {
      totalProbability += rewardProbabilitis[i];
    }

    require(totalProbability == 100, "The total probability should be 100!");

    uint256 ruleId = nextRuleId++;
    ruleset[ruleId].ruleId = ruleId;
    ruleset[ruleId].owner = msg.sender;
    ruleset[ruleId].createTime = block.timestamp;
    ruleset[ruleId].available = true;

    for (uint256 i = 0; i < rewardProbabilitis.length; i++) {
      ProbabilityItem memory newItem = ProbabilityItem(rewardNames[i], rewardProbabilitis[i]);
      ruleset[ruleId].lotteryProbabilities.push(newItem);
    }

    owner2rules[msg.sender].push(ruleId);   
    return ruleId;
  }

  function getRules() view public returns(uint256[] memory) {
    return owner2rules[msg.sender];
  }

  function getRule(uint256 ruleId) view public returns(Rule memory) {
    return ruleset[ruleId];
  }

  function select(ProbabilityItem[] memory probabilities) view external returns (string memory) {
        
        uint sum = 0;
        for(uint i = 0; i < probabilities.length; i++) {
            sum += probabilities[i].p;
            if(randomResult < sum) {
                return probabilities[i].name;
            }
        }

        return '';
    }

    function getReward(uint256 ruleId) public returns(bytes32) {
        // Rule storage rule = ruleset[ruleId];
        // return this.select(rule.lotteryProbabilities);
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        bytes32 requestId = requestRandomness(keyHash, fee);
        requestToRuleId[requestId] = ruleId;
        return requestId;
    }

  fallback() external {
    revert("something wrong");
  }

  event RewardSelected(bytes32 requestId, string reward);
}

// ["Phone", "Laptop", "Mouse", "Nothing, Damn!"]
// [20, 10, 30, 40]