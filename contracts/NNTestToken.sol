pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NNTestToken is ERC20 {
    constructor(
        string memory name,
        string memory symbol) ERC20(name, symbol)
    public {}

    function mint(address recipient, uint amount) external {
        _mint(recipient, amount);
    }
}