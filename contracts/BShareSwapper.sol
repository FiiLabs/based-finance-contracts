// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IOracle.sol";
import "./owner/Operator.sol";
import "./interfaces/ITreasury.sol";

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
   

    function getBasedPrice() public view returns (uint256 basedPrice) {
        try IOracle(basedOracle).consult(based, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult BASED price from the oracle");
        }
    }
    function getBsharePrice() public view returns (uint256 bsharePrice) {
        try IOracle(bshareOracle).consult(bshare, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult BSHARE price from the oracle");
        }
    }

    function getRedeemableBonds() public view returns (uint256 redeemableBonds) {
        try IOracle(ITreasury).getRedeemableBonds() returns (uint256) {
        } catch {
            revert("Treasury: failed to consult BSHARE price from the oracle");
        }
    }


    function estimateAmountOfBShare(uint256 _bbondAmount) external view returns (uint256) {
        uint256 bshareAmountPerBased = getBShareAmountPerBased();
        return _bbondAmount.mul(bshareAmountPerBased).div(1e18);
    }

    function swapBBondToBShare(uint256 _bbondAmount) external {
      
        require(getBBondBalance(msg.sender) >= _bbondAmount, "Not enough BBond in wallet");
        // check if redeeamable bonds are > _bbondAmount
        try  IOracle(ITreasury).getRedeemableBonds() returns (uint256) {
        } catch {
            revert("Treasury: failed to consult BSHARE price from the oracle");
        }
       // send our bbond to treasury(call redeem bonds in treasury)
       // we receive back based from treasury
       // swap based to bshare and send back to user
        //require(getBShareBalance() >= bshareAmount, "Not enough BShare.");

       uint256 bshareAmount = this.estimateAmountOfBShare(_bbondAmount);
       // bbond.safeTransferFrom(msg.sender, daoAddress, _bbondAmount);
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
    
    function getBShareAmountPerBased() public view returns (uint256) {
        uint256 basedPrice = getBasedPrice();
        uint256 bsharePrice = getBsharePrice();
        return basedPrice.mul(1e18).div(bsharePrice);
    }

}