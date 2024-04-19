pragma solidity 0.8.19;
contract MyToken {
  mapping (address => uint256) private balances;
  uint256 public totalSupply;
  address private owner;

  constructor(){
      owner = msg.sender;
  }
}