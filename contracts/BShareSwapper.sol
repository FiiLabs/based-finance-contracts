// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IOracle.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IZapper.sol";

import "./owner/Operator.sol";

contract BShareSwapper is Operator {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public based;
    address public bshare;
    address public bbond;

    address public basedOracle;
    address public bshareOracle;
    address public treasury;
    address public zapper;

    

    mapping (address => bool) public useNativeRouter;

    event BBondSwapPerformed(address indexed sender, uint256 bbondAmount, uint256 bshareAmount);


    constructor(
        address _based,
        address _bbond,
        address _bshare,
        address _basedOracle,
        address _bshareOracle,
        address _treasury,
        address _zapper
    ) {
        based = _based;
        bbond = _bbond;
        bshare = _bshare;
        basedOracle = _basedOracle;
        bshareOracle = _bshareOracle;
        treasury = _treasury;
        zapper = _zapper;
    }
   modifier whitelist(address route) {
        require(useNativeRouter[route], "route not allowed");
        _;
    }

     function _approveTokenIfNeeded(address token, address router) private {
        if (IERC20(token).allowance(address(this), router) == 0) {
            IERC20(token).safeApprove(router, type(uint256).max);
        }
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
    function redeemBonds(uint256 _bbondAmount, uint256 basedPrice) private returns (uint256) {

         IERC20(bbond).safeTransferFrom(msg.sender, address(this), _bbondAmount);
         _approveTokenIfNeeded(bbond, treasury);
       
        try ITreasury(treasury).redeemBonds(_bbondAmount, basedPrice) {
        } catch {
            revert("Treasury: cant redeem bonds");
        }
        return getBasedBalance();
    }

    function swap(address _in, uint256 amount, address out, address recipient, address routerAddr, uint256 minAmountOfBshare) private returns (uint256) {
        
        IERC20(based).safeTransferFrom(address(this), zapper, amount);
        _approveTokenIfNeeded(based, routerAddr);
        
         try IZapper(zapper)._swap(_in, amount, out, recipient, routerAddr , minAmountOfBshare) returns (uint256 _bshareAmount) {
             require( _bshareAmount >= minAmountOfBshare, "amt < minAmountNeeded");
            return uint256(_bshareAmount);
        } catch {
            revert("Treasury: failed to get BSHARE price");
        }
    }
   

    function estimateAmountOfBShare(uint256 _bbondAmount) external view returns (uint256) {
        uint256 bshareAmountPerBased = getBShareAmountPerBased();
        return _bbondAmount.mul(bshareAmountPerBased).div(1e18);
    }

    function swapBBondToBShare(uint256 _bbondAmount, address routerAddr, uint256 minAmountofBshare) external whitelist(routerAddr) {
        //check if we have the amount of bbonds we want to swap
        require(getBBondBalance(msg.sender) >= _bbondAmount, "Not enough BBond in wallet");
        
       // send bbond to treasury(call redeem bonds in treasury) and receive based back
        uint256 basedPrice = getBasedPrice();
        uint256 basedToSwap = redeemBonds(_bbondAmount, basedPrice);
       // check if we received based(should be more than bbonds because of higher rate in redeem in treasury)
       require ( basedToSwap >= _bbondAmount, "redeem bonds reverted"); 
       // swap based to bshare
        uint256 bshareReceived = swap(based, basedToSwap, bshare, msg.sender, routerAddr, minAmountofBshare);

        emit BBondSwapPerformed(msg.sender, _bbondAmount, bshareReceived);
    }


    function getBasedBalance() public view returns (uint256) {
        return IERC20(based).balanceOf(address(this));
    }
    function getBShareBalance() public view returns (uint256) {
        return IERC20(bshare).balanceOf(address(this));
    }

    function getBBondBalance(address _user) public view returns (uint256) {
        return IERC20(bbond).balanceOf(_user);
    }
    
    function getBShareAmountPerBased() public view returns (uint256) {
        uint256 basedPrice = getBasedPrice();
        uint256 bsharePrice = getBsharePrice();
        return basedPrice.mul(1e18).div(bsharePrice);
    }
    function setUseNativeRouter(address router) external onlyOwner {
        useNativeRouter[router] = true;
    }

    function removeNativeRouter(address router) external onlyOwner {
        useNativeRouter[router] = false;
    }

}