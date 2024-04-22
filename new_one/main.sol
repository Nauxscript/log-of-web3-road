pragma solidity ^0.8.17;  
contract MyNFT {
  struct Token {
    string name;
    string description;
    address owner;
  }

  mapping(uint256 => Token) private tokens;

  mapping(address => uint256[]) private ownerTokens;

  uint256 nextTokenId = 1;  

  function mint(string memory _name, string memory _description) public returns(uint256) {
    Token memory newNFT = Token(_name, _description, msg.sender);
    uint256 tokenId = nextTokenId;
    ownerTokens[msg.sender].push(tokenId); 
    nextTokenId++;
    return tokenId;
  }
}