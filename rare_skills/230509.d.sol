pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "./230509.sol";

contract ContractBTest is Test {
  address victim;
  address attacker;
  function setUp() public {
    victim = address(new Security101());
    vm.deal(victim, 10000 ether);

    attacker = vm.addr(uint256(keccak256(abi.encodePacked(uint(2)))));
    vm.deal(attacker, 1 ether);
    vm.startPrank(attacker);
  }

  function test_run() public {
    OptimizedAttackerSecurity101 attack_contract =
      new OptimizedAttackerSecurity101{value: 1 ether}(victim);
    assertGt(attacker.balance, 9900 ether);
    assertEq(victim.balance, 0 ether);
  }
}
