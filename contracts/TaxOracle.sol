// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
__________                             .___   ___________.__
\______   \_____     ______  ____    __| _/   \_   _____/|__|  ____  _____     ____    ____   ____
 |    |  _/\__  \   /  ___/_/ __ \  / __ |     |    __)  |  | /    \ \__  \   /    \ _/ ___\_/ __ \
 |    |   \ / __ \_ \___ \ \  ___/ / /_/ |     |     \   |  ||   |  \ / __ \_|   |  \\  \___\  ___/
 |______  /(____  //____  > \___  >\____ |     \___  /   |__||___|  /(____  /|___|  / \___  >\___  >
        \/      \/      \/      \/      \/         \/             \/      \/      \/      \/     \/
*/
contract BasedTaxOracle is Ownable {
    using SafeMath for uint256;

    IERC20 public based;
    IERC20 public wftm;
    address public pair;

    constructor(
        address _based,
        address _wftm,
        address _pair
    ) {
        require(_based != address(0), "based address cannot be 0");
        require(_wftm != address(0), "wftm address cannot be 0");
        require(_pair != address(0), "pair address cannot be 0");
        based = IERC20(_based);
        wftm = IERC20(_wftm);
        pair = _pair;
    }

    //TODO figure out if uint256 _amountIn is required
    function consult(address _token /*uint256 _amountIn*/) external view returns (uint144 amountOut) {
        require(_token == address(based), "token needs to be based");
        uint256 basedBalance = based.balanceOf(pair);
        uint256 wftmBalance = wftm.balanceOf(pair);
        return uint144(basedBalance.div(wftmBalance));
    }

    function setBased(address _based) external onlyOwner {
        require(_based != address(0), "based address cannot be 0");
        based = IERC20(_based);
    }

    function setWftm(address _wftm) external onlyOwner {
        require(_wftm != address(0), "wftm address cannot be 0");
        wftm = IERC20(_wftm);
    }

    function setPair(address _pair) external onlyOwner {
        require(_pair != address(0), "pair address cannot be 0");
        pair = _pair;
    }



}