// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

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

contract Lottery {
  uint256 nextRuleId = 1;
  mapping (uint256 => Rule) ruleset;
  mapping (address => uint256[]) owner2rules;

  constructor() {}

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

  fallback() external {
    revert("something wrong");
  }
}

// ["Phone", "Laptop", "Mouse", "Nothing, Damn!"]
// [20, 10, 30, 40]