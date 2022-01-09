// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.8.0;

contract Migrations {
    address public owner;
    uint256 public last_completed_migration;

    constructor() public {
        owner = msg.sender;
    }

    modifier restricted() {
        if (msg.sender == owner) _;
    }

    function setCompleted(uint256 completed) public restricted {
        last_completed_migration = completed;
    }

    function upgrade(address new_adress) public restricted {
        Migrations upgraded = Migration(new_adress);
        upgraded.setCompleted(last_completed_migration);
    }
}
