pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "./230509.sol";

contract Problem230509Test is Test {
  address victim;
  address attacker;
  function setUp() public {
    vm.prank(address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));
    victim = address(new Security101());
    vm.deal(victim, 10000 ether);

    attacker = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
    vm.deal(attacker, 1 ether);
    vm.roll(2);
    vm.startPrank(attacker, attacker);
  }

  function test_run() public {
    new OptimizedAttackerSecurity101{value: 1 ether}(victim);
    assertGt(attacker.balance, 9900 ether);
    assertEq(victim.balance, 0 ether);
  }
}
