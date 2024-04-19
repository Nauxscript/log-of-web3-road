pragma solidity 0.8.19;
contract MyToken {
  mapping (address => uint256) private balances;
  uint256 public totalSupply;
  address private owner;

  constructor(){
      owner = msg.sender;
  }

  function mint(address recipient, uint256 amount) public {
    // Only the owner can mint tokens
    require(msg.sender == owner, "You are not the owner");

    // Increase the balance of the recipient by the amount
    balances[recipient] += amount;

    // Increase the total supply, because new tokens are created
    totalSupply += amount;

  }
}