pragma solidity 0.8.19;

contract MyToken {

	address private owner;
    constructor(){
      owner = msg.sender;
    }
}