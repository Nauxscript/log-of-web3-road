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

  function getNFT(uint256 _tokenId) public view returns(string memory name, string memory description, address owner) {
    require(_tokenId >= 1 && _tokenId < nextTokenId, "Invalid token ID");
    Token memory token = tokens[_tokenId];
    name = token.name;
    description = token.description;
    owner = token.owner;
  }

  function getTokensByOwner(address _owner) public view returns(uint256[] memory) {
    return ownerTokens[_owner];
  }

  function transfer(address _to, uint256 _tokenId) public {
    require(_to != address(0), "Invalid recipient");
    require(_tokenId >= 1 && _tokenId < nextTokenId, "Invalid tokenID");
    Token storage token = tokens[_tokenId];

    require(msg.sender == token.owner, "You don't own this token");

    token.owner = _to;

    deleteById(msg.sender, _tokenId);
    ownerTokens[_to].push(_tokenId);
  }

  function deleteById(address /*account*/, uint256 _tokenId) internal {
    uint256[] storage ownerTokenList = ownerTokens[msg.sender];
    for (uint256 i = 0; i < ownerTokenList.length; i++) {
      if (ownerTokenList[i] == _tokenId) {
        ownerTokenList[i] = ownerTokenList[ownerTokenList.length - 1];
        ownerTokenList.pop();
        break;
      }
    }
  }
}
