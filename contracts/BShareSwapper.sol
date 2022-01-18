// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./owner/Operator.sol";

contract BShareSwapper is Operator {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public based;
    IERC20 public bbond;
    IERC20 public bshare;

    address public basedSpookyLpPair;
    address public bshareSpookyLpPair;

    address public wftmAddress;

    address public daoAddress;

    event BBondSwapPerformed(address indexed sender, uint256 bbondAmount, uint256 bshareAmount);


    constructor(
        address _based,
        address _bbond,
        address _bshare,
        address _wftmAddress,
        address _basedSpookyLpPair,
        address _bshareSpookyLpPair,
        address _daoAddress
    ) {
        based = IERC20(_based);
        bbond = IERC20(_bbond);
        bshare = IERC20(_bshare);
        wftmAddress = _wftmAddress;
        basedSpookyLpPair = _basedSpookyLpPair;
        bshareSpookyLpPair = _bshareSpookyLpPair;
        daoAddress = _daoAddress;
    }


    modifier isSwappable() {
        //TODO: What is a good number here?
        require(based.totalSupply() >= 60 ether, "ChipSwapMechanismV2.isSwappable(): Insufficient supply.");
        _;
    }

    function estimateAmountOfBShare(uint256 _bbondAmount) external view returns (uint256) {
        uint256 bshareAmountPerBased = getBShareAmountPerBased();
        return _bbondAmount.mul(bshareAmountPerBased).div(1e18);
    }

    function swapBBondToBShare(uint256 _bbondAmount) external {
        require(getBBondBalance(msg.sender) >= _bbondAmount, "Not enough BBond in wallet");

        uint256 bshareAmountPerBased = getBShareAmountPerBased();
        uint256 bshareAmount = _bbondAmount.mul(bshareAmountPerBased).div(1e18);
        require(getBShareBalance() >= bshareAmount, "Not enough BShare.");

        bbond.safeTransferFrom(msg.sender, daoAddress, _bbondAmount);
        bshare.safeTransfer(msg.sender, bshareAmount);

        emit BBondSwapPerformed(msg.sender, _bbondAmount, bshareAmount);
    }

    function withdrawBShare(uint256 _amount) external onlyOperator {
        require(getBShareBalance() >= _amount, "ChipSwapMechanism.withdrawFish(): Insufficient FISH balance.");
        bshare.safeTransfer(msg.sender, _amount);
    }

    function getBShareBalance() public view returns (uint256) {
        return bshare.balanceOf(address(this));
    }

    function getBBondBalance(address _user) public view returns (uint256) {
        return bbond.balanceOf(_user);
    }

    function getBasedPrice() public view returns (uint256) {
        return IERC20(wftmAddress).balanceOf(basedSpookyLpPair)
        .mul(1e18)
        .div(based.balanceOf(basedSpookyLpPair));
    }

    function getBSharePrice() public view returns (uint256) {
        return IERC20(wftmAddress).balanceOf(bshareSpookyLpPair)
        .mul(1e18)
        .div(bshare.balanceOf(bshareSpookyLpPair));
    }

    function getBShareAmountPerBased() public view returns (uint256) {
        uint256 basedPrice = IERC20(wftmAddress).balanceOf(basedSpookyLpPair)
        .mul(1e18)
        .div(based.balanceOf(basedSpookyLpPair));

        uint256 bsharePrice =
        IERC20(wftmAddress).balanceOf(bshareSpookyLpPair)
        .mul(1e18)
        .div(bshare.balanceOf(bshareSpookyLpPair));


        return basedPrice.mul(1e18).div(bsharePrice);
    }

}