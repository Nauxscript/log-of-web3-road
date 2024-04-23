pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract SimpleCryptoKitties is ERC721 {
  uint256 public _tokenIdCounter = 1;

  struct Kitty {
    uint256 genes;
    uint256 birthTime;
    uint256 momId;
    uint256 dadId;
    uint256 generation;
  } 

  mapping (uint256 => Kitty) public kitties;

  constructor() ERC721("SimpleCryptoKitties", "SCK") {}

  function createKittyGen0() public returns(uint256) {
    uint256 genes = uint256(keccak256(abi.encodePacked(block.timestamp, _tokenIdCounter)));
    return _createKitty(0, 0, 0, genes, msg.sender);
  }

  function _createKitty(uint256 momId, uint256 dadId, uint256 generation, uint256 genes, address owner) private returns(uint256) {

    kitties[_tokenIdCounter] = Kitty(genes, block.timestamp, momId, dadId, generation);
    _mint(owner, _tokenIdCounter);
    return _tokenIdCounter++;
  }

  function breed(uint256 momId, uint256 dadId) public returns(uint256) {
    require(momId != dadId, "both ids are the same!");
    require(momId == msg.sender, "Not the owner of the mom kitty");
    require(dadId == msg.sender, "Not the owner of the dad kitty");

    Kitty memory mom = kitties[momId];
    Kitty memory dad = kitties[dadId];

    uint256 newGeneration = (mom.generation > dad.generation ? mom.generation : dad.generation) + 1;
    uint256 newGenes = (mom.genes + dad.genes) / 2;

    return _createKitty(momId, dadId, newGeneration, newGenes, msg.sender);
  }
}