// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IVault.sol";
import "./lib/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BasedTombZap is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    // @NATIVE - native token that is not a part of our zap-in LP
    address private NATIVE;

    struct LiquidityPair {
        uint256 amountA;
        uint256 amountB;
        uint256 liquidity;
    }

    struct FunctionArgs {
        address _from;
        uint256 _amount;
        address _to;
        address _recipient;
        address _routerAddr;
        uint256 _slippage;
        address _LP;
        address _token0;
        address _token1;
        uint256 _otherAmount;
        address _token;
        uint256 _swapValue;
    }

    mapping(address => mapping(address => address)) private tokenBridgeForRouter;

    mapping(address => bool) public useNativeRouter;

    modifier whitelist(address route) {
        require(useNativeRouter[route], "route not allowed");
        _;
    }

    // BShare address
    constructor(address _NATIVE) Ownable() {
        NATIVE = _NATIVE;
    }

    /* ========== External Functions ========== */

    receive() external payable {}

    function NativeToken() public view returns (address) {
        return NATIVE;
    }

    // @_from - Token we want to throw in
    // @amount - amount of our _from
    // @_to - LP address we are going to get from this zap-in function

    function zapInToken(address _from, uint256 amount, address _to, address routerAddr, address _recipient, uint256 slippage) external whitelist(routerAddr) {
        // From an ERC20 to an LP token, through specified router, going through base asset if necessary
        IERC20(_from).safeTransferFrom(msg.sender, address(this), amount);
        // we'll need this approval to add liquidity
        _approveTokenIfNeeded(_from, amount, routerAddr);
        _swapTokenToLP(_from, amount, _to, _recipient, routerAddr, slippage);
    }

    function estimateZapInToken(address _from, address _to, address _router, uint256 _amt) public view whitelist(_router) returns (uint256, uint256) {
        // get pairs for desired lp
        // check if we already have one of the assets
        if (_from == IUniswapV2Pair(_to).token0() || _from == IUniswapV2Pair(_to).token1()) {
            // if so, we're going to sell half of _from for the other token we need
            // figure out which token we need, and approve
            address other = _from == IUniswapV2Pair(_to).token0() ? IUniswapV2Pair(_to).token1() : IUniswapV2Pair(_to).token0();
            // calculate amount of _from to sell
            uint256 sellAmount = _amt.div(2);
            // calculate amount of other token for potential lp
            uint256 otherAmount = _estimateSwap(_from, sellAmount, other, _router);
            if (_from == IUniswapV2Pair(_to).token0()) {
                return (sellAmount, otherAmount);
            } else {
                return (otherAmount, sellAmount);
            }
        } else {
            // go through native token, that's not in our LP, for highest liquidity
            uint256 nativeAmount = _from == NATIVE ? _amt : _estimateSwap(_from, _amt, NATIVE, _router);
            return estimateZapIn(_to, _router, nativeAmount);
        }
    }

    function estimateZapIn(address _LP, address _router, uint256 _amt) public view whitelist(_router) returns (uint256, uint256) {
        uint256 zapAmt = _amt.div(2);

        IUniswapV2Pair pair = IUniswapV2Pair(_LP);
        address token0 = pair.token0();
        address token1 = pair.token1();

        if (token0 == NATIVE || token1 == NATIVE) {
            address token = token0 == NATIVE ? token1 : token0;
            uint256 tokenAmt = _estimateSwap(NATIVE, zapAmt, token, _router);
            if (token0 == NATIVE) {
                return (zapAmt, tokenAmt);
            } else {
                return (tokenAmt, zapAmt);
            }
        } else {
            uint256 token0Amt = _estimateSwap(NATIVE, zapAmt, token0, _router);
            uint256 token1Amt = _estimateSwap(NATIVE, zapAmt, token1, _router);

            return (token0Amt, token1Amt);
        }
    }
    // from Native to an LP token through the specified router
    function zapIn(address _to, address routerAddr, address _recipient, uint256 slippage) external payable whitelist(routerAddr) {
        _swapNativeToLP(_to, msg.value, _recipient, routerAddr, slippage);
    }

    // from an LP token to Native through specified router
    function zapOut(address _from, uint256 amount, address routerAddr, address _recipient, uint256 minAmountToken0, uint256 minAmountToken1, uint256 slippage) external whitelist(routerAddr) {
        // take the LP token
        IERC20(_from).safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(_from, amount, routerAddr);

        LiquidityPair memory pair;
        // get pairs for LP
        address token0 = IUniswapV2Pair(_from).token0();
        address token1 = IUniswapV2Pair(_from).token1();
        _approveTokenIfNeeded(token0, minAmountToken0, routerAddr);
        _approveTokenIfNeeded(token1, minAmountToken1, routerAddr);

        (pair.amountA, pair.amountB) = IUniswapV2Router(routerAddr).removeLiquidity(token0, token1, amount, minAmountToken0.sub(minAmountToken0.mul(slippage)), minAmountToken1.sub(minAmountToken1.mul(slippage)), address(this), block.timestamp);
        if (token0 != NATIVE) {
            pair.amountA = _swapTokenForNative(token0, pair.amountA, address(this), routerAddr, slippage);
        }
        if (token1 != NATIVE) {
            pair.amountB = _swapTokenForNative(token1, pair.amountB, address(this), routerAddr, slippage);
        }
        IERC20(NATIVE).safeTransfer(_recipient, pair.amountA.add(pair.amountB));

    }
    // from an LP token to an ERC20 through specified router

    function zapOutToken(address _LP, uint256 amount, address _to, address routerAddr, address _recipient, uint256 minAmountToken0, uint256 minAmountToken1, uint256 slippage) whitelist(routerAddr) external {
        FunctionArgs memory args;

        args._amount = amount;
        args._to = _to;
        args._recipient = _recipient;
        args._routerAddr = routerAddr;
        args._slippage = slippage;
        args._swapValue = args._amount.div(2);
        args._LP = _LP;

        IERC20(args._LP).safeTransferFrom(msg.sender, address(this), args._amount);
        _approveTokenIfNeeded(args._LP, args._amount, args._routerAddr);

        args._token0 = IUniswapV2Pair(args._LP).token0();
        args._token1 = IUniswapV2Pair(args._LP).token1();
        _approveTokenIfNeeded(args._token0, minAmountToken0, args._routerAddr);
        _approveTokenIfNeeded(args._token1, minAmountToken1, args._routerAddr);
        // estimate function call, and get the AmountsOut from it
        //we can assign AmountsOut to our local variables..
        LiquidityPair memory pair;
        //uint256 estimationOfTokensAfterRemoveLiquidity = estimateZapOutToken(_LP, _to, routerAddr, amount, minAmountToken0, minAmountToken1, slippage );
        (pair.amountA, pair.amountB) = IUniswapV2Router(routerAddr).removeLiquidity(args._token0, args._token1, args._amount, minAmountToken0.sub(minAmountToken0.mul(args._slippage).div(10000)), minAmountToken1.sub(minAmountToken1.mul(args._slippage).div(10000)), address(this), block.timestamp);
        if (args._token0 != _to) {
            pair.amountA = _swap(args._token0, pair.amountA, args._to, address(this), args._routerAddr, args._slippage);
        }
        if (args._token1 != args._to) {
            pair.amountB = _swap(args._token1, pair.amountB, args._to, address(this), args._routerAddr, args._slippage);
        }
        IERC20(args._to).safeTransfer(args._recipient, pair.amountA.add(pair.amountB));
    }

    function swapToken(address _from, uint256 amount, address _to, address routerAddr, address _recipient, uint256 slippage) external whitelist(routerAddr) {
        IERC20(_from).safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(_from, amount, routerAddr);
        _swap(_from, amount, _to, _recipient, routerAddr, slippage);
    }

    function swapToNative(address _from, uint256 amount, address routerAddr, address _recipient, uint256 slippage) external whitelist(routerAddr) {
        IERC20(_from).safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(_from, amount, routerAddr);
        _swapTokenForNative(_from, amount, _recipient, routerAddr, slippage);
    }


    /* ========== Private Functions ========== */

    function _approveTokenIfNeeded(address token, uint256 amount, address router) private {
        if (IERC20(token).allowance(address(this), router) <= amount) {
            IERC20(token).safeApprove(router, IERC20(token).allowance(address(this), router).add(amount));
        }
    }

    function _swapTokenToLP(address from, uint256 amount, address to, address recipient, address routerAddr, uint256 slippage) private returns (uint256) {
        // get pairs for desired lp
        FunctionArgs memory args;
        args._from = from;
        args._amount = amount;
        args._to = to;
        args._recipient = recipient;
        args._routerAddr = routerAddr;
        args._slippage = slippage;

        if (args._from == IUniswapV2Pair(args._to).token0() || args._from == IUniswapV2Pair(args._to).token1()) { // check if we already have one of the assets
            // if so, we're going to sell half of _from for the other token we need
            // figure out which token we need, and approve
            args._token = args._from == IUniswapV2Pair(args._to).token0() ? IUniswapV2Pair(args._to).token1() : IUniswapV2Pair(args._to).token0();
            _approveTokenIfNeeded(args._token, args._amount.div(2), args._routerAddr);
            // calculate args._amount of _from to sell
            uint256 sellAmount = args._amount.div(2);
            // execute swap
            uint256 otherAmount = _swap(args._from, sellAmount, args._token, address(this), args._routerAddr,  args._slippage);
            LiquidityPair memory pair;
            (pair.amountA , pair.amountB , pair.liquidity) = IUniswapV2Router(args._routerAddr).addLiquidity(args._from, args._token, args._amount.sub(sellAmount), otherAmount, args._amount.sub(sellAmount).sub(args._amount.sub(sellAmount).mul( args._slippage)) , otherAmount.sub(otherAmount.mul( args._slippage)), args._recipient, block.timestamp);
            _dustDistribution(args._amount.sub(sellAmount), otherAmount, pair.amountA, pair.amountB, args._from, args._token);
            return pair.liquidity;
        } else {
            // go through native token for highest liquidity
            uint256 nativeAmount = _swapTokenForNative(args._from, args._amount, address(this), args._routerAddr,  args._slippage);
            return _swapNativeToLP(args._to, nativeAmount, args._recipient, args._routerAddr,  args._slippage);
        }
    }

    function _swapNativeToLP(address _LP, uint256 amount, address recipient, address routerAddress, uint256 slippage) private returns (uint256) {
        // LP
        IUniswapV2Pair pair = IUniswapV2Pair(_LP);
        address token0 = pair.token0();  // based
        address token1 = pair.token1();  // tomb
        uint256 liquidity;

        liquidity = _swapNativeToEqualTokensAndProvide(token0, token1, amount, routerAddress, recipient, slippage);
        return liquidity;
    }

    function _dustDistribution(uint256 token0, uint256 token1, uint256 amountA, uint256 amountB, address native, address token) private {
        uint256 nativeDust = token0.sub(amountA);
        uint256 tokenDust = token1.sub(amountB);
        if (nativeDust > 0) {
            IERC20(native).safeTransferFrom(address(this), msg.sender, nativeDust);
        }
        if (tokenDust > 0) {
            IERC20(token).safeTransferFrom(address(this), msg.sender, tokenDust);
        }

    }


    function _swapNativeToEqualTokensAndProvide(address token0, address token1, uint256 amount, address routerAddress, address recipient, uint256 slippage) private returns (uint256) {
        FunctionArgs memory args;
        args._token0 = token0;
        args._amount = amount;
        args._token1 = token1;
        args._recipient = recipient;
        args._routerAddr = routerAddress;
        args._slippage = slippage;
        args._swapValue = args._amount.div(2);

        LiquidityPair memory pair;

        IUniswapV2Router router = IUniswapV2Router(args._routerAddr);

        if (args._token0 == NATIVE) {
            uint256 token1Amount = _swapNativeForToken(args._token1, args._swapValue, address(this), args._routerAddr, args._slippage);
            _approveTokenIfNeeded(args._token0, args._amount.div(2), args._routerAddr);
            _approveTokenIfNeeded(args._token1, token1Amount, args._routerAddr);

            (pair.amountA, pair.amountB, pair.liquidity) = router.addLiquidity(args._token0, args._token1, args._swapValue, token1Amount, args._swapValue.sub(args._swapValue.mul(args._slippage).div(10000)), token1Amount.sub(token1Amount.mul(args._slippage)), args._recipient, block.timestamp);
            _dustDistribution(args._swapValue, token1Amount, pair.amountA, pair.amountB, args._token0, args._token1);
            return pair.liquidity;
        } else {
            uint256 token0Amount = _swapNativeForToken(args._token0,  args._swapValue, address(this), args._routerAddr, args._slippage);
            _approveTokenIfNeeded(args._token0, token0Amount, args._routerAddr);
            _approveTokenIfNeeded( args._token1, args._swapValue, args._routerAddr);
            (pair.amountA, pair.amountB, pair.liquidity) = router.addLiquidity(args._token0,  args._token1, token0Amount, args._amount.sub( args._swapValue), token0Amount.sub(token0Amount.mul(args._slippage)), args._amount.sub( args._swapValue).sub(args._amount.sub( args._swapValue).mul(args._slippage)), args._recipient, block.timestamp);
            _dustDistribution(token0Amount, args._amount.sub( args._swapValue), pair.amountA, pair.amountB,  args._token1, args._token0);
            return pair.liquidity;
        }
    }

    function _swapNativeForToken(address token, uint256 value, address recipient, address routerAddr, uint256 slippage) private returns (uint256) {
        address[] memory path;
        IUniswapV2Router router = IUniswapV2Router(routerAddr);

        if (tokenBridgeForRouter[token][routerAddr] != address(0)) {
            path = new address[](3);
            path[0] = NATIVE;
            path[1] = tokenBridgeForRouter[token][routerAddr];
            path[2] = token;
        } else {
            path = new address[](2);
            path[0] = NATIVE;
            path[1] = token;
        }
        uint256 tokenAmt = _estimateSwap(NATIVE, value, token, routerAddr);
        uint256[] memory amounts = router.swapExactTokensForTokens(value, tokenAmt.sub(tokenAmt.mul(slippage).div(10000)), path, recipient, block.timestamp);
        return amounts[amounts.length - 1];
    }

    function _swapTokenForNative(address token, uint256 amount, address recipient, address routerAddr, uint256 slippage) private returns (uint256) {
        address[] memory path;
        IUniswapV2Router router = IUniswapV2Router(routerAddr);

        if (tokenBridgeForRouter[token][routerAddr] != address(0)) {
            path = new address[](3);
            path[0] = token;
            path[1] = tokenBridgeForRouter[token][routerAddr];
            path[2] = NATIVE;
        } else {
            path = new address[](2);
            path[0] = token;
            path[1] = NATIVE;
        }

        uint256 tokenAmt = _estimateSwap(token, amount, NATIVE, routerAddr);
        uint256[] memory amounts = router.swapExactTokensForTokens(amount, tokenAmt.sub(tokenAmt.mul(slippage).div(10000)), path, recipient, block.timestamp);
        return amounts[amounts.length - 1];
    }

    function _swap(address _from, uint256 amount, address _to, address recipient, address routerAddr, uint256 slippage) private returns (uint256) {
        IUniswapV2Router router = IUniswapV2Router(routerAddr);

        address fromBridge = tokenBridgeForRouter[_from][routerAddr];
        address toBridge = tokenBridgeForRouter[_to][routerAddr];

        address[] memory path;

        if (fromBridge != address(0) && toBridge != address(0)) {
            if (fromBridge != toBridge) {
                path = new address[](5);
                path[0] = _from;
                path[1] = fromBridge;
                path[2] = NATIVE;
                path[3] = toBridge;
                path[4] = _to;
            } else {
                path = new address[](3);
                path[0] = _from;
                path[1] = fromBridge;
                path[2] = _to;
            }
        } else if (fromBridge != address(0)) {
            if (_to == NATIVE) {
                path = new address[](3);
                path[0] = _from;
                path[1] = fromBridge;
                path[2] = NATIVE;
            } else {
                path = new address[](4);
                path[0] = _from;
                path[1] = fromBridge;
                path[2] = NATIVE;
                path[3] = _to;
            }
        } else if (toBridge != address(0)) {
            path = new address[](4);
            path[0] = _from;
            path[1] = NATIVE;
            path[2] = toBridge;
            path[3] = _to;
        } else if (_from == NATIVE || _to == NATIVE) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            // Go through Native
            path = new address[](3);
            path[0] = _from;
            path[1] = NATIVE;
            path[2] = _to;
        }
        uint256 tokenAmountEst = _estimateSwap(_from, amount, _to, routerAddr);

        uint256[] memory amounts = router.swapExactTokensForTokens(amount, tokenAmountEst.sub(tokenAmountEst.mul(slippage).div(10000)), path, recipient, block.timestamp);
        return amounts[amounts.length - 1];
    }

    function _estimateSwap(address _from, uint256 amount, address _to, address routerAddr) private view returns (uint256) {
        IUniswapV2Router router = IUniswapV2Router(routerAddr);

        address fromBridge = tokenBridgeForRouter[_from][routerAddr];
        address toBridge = tokenBridgeForRouter[_to][routerAddr];

        address[] memory path;

        if (fromBridge != address(0) && toBridge != address(0)) {
            if (fromBridge != toBridge) {
                path = new address[](5);
                path[0] = _from;
                path[1] = fromBridge;
                path[2] = NATIVE;
                path[3] = toBridge;
                path[4] = _to;
            } else {
                path = new address[](3);
                path[0] = _from;
                path[1] = fromBridge;
                path[2] = _to;
            }
        } else if (fromBridge != address(0)) {
            if (_to == NATIVE) {
                path = new address[](3);
                path[0] = _from;
                path[1] = fromBridge;
                path[2] = NATIVE;
            } else {
                path = new address[](4);
                path[0] = _from;
                path[1] = fromBridge;
                path[2] = NATIVE;
                path[3] = _to;
            }
        } else if (toBridge != address(0)) {
            path = new address[](4);
            path[0] = _from;
            path[1] = NATIVE;
            path[2] = toBridge;
            path[3] = _to;
        } else if (_from == NATIVE || _to == NATIVE) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            // Go through Native
            path = new address[](3);
            path[0] = _from;
            path[1] = NATIVE;
            path[2] = _to;
        }

        uint256[] memory amounts = router.getAmountsOut(amount, path);
        return amounts[amounts.length - 1];
    }

    function estimateZapOutToken(address _fromLp, address _to, address _router, uint256 minAmountToken0, uint256 minAmountToken1 ) public view whitelist(_router) returns (uint256) {
        address token0 = IUniswapV2Pair(_fromLp).token0();
        address token1 = IUniswapV2Pair(_fromLp).token1();
        if(_to == NATIVE) {
            if(token0 == NATIVE) {
                return _estimateSwap(token1, minAmountToken1, _to, _router).add(minAmountToken0);
            } else {
                return _estimateSwap(token0, minAmountToken0, _to, _router).add(minAmountToken1);
            }
        }

        if(token0 == NATIVE) {

            if(_to == token1) {
                // swap everything to based
                return _estimateSwap(token0, minAmountToken0, _to, _router).add(minAmountToken1);

            } else {
                // swap everything to bshare
                uint256 halfAmountof_to = _estimateSwap(token0, minAmountToken0, _to, _router);
                uint256 halfAmountof_too = _estimateSwap(token1, minAmountToken1, _to, _router);
                return (halfAmountof_to.add(halfAmountof_too));
            }
        } else {
            if (_to == token0) {
                //swap everythig to based
                return _estimateSwap(token1, minAmountToken1, _to, _router).add(minAmountToken0);

            } else {
                // swap everything to bshare
                uint256 halfAmountof_to = _estimateSwap(token0, minAmountToken0, _to, _router);
                uint256 halfAmountof_too = _estimateSwap(token1, minAmountToken1, _to, _router);
                return halfAmountof_to.add(halfAmountof_too);
            }
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setNativeToken(address _NATIVE) external onlyOwner {
        NATIVE = _NATIVE;
    }

    function setTokenBridgeForRouter(address token, address router, address bridgeToken) external onlyOwner {
        tokenBridgeForRouter[token][router] = bridgeToken;
    }

    function setUseNativeRouter(address router) external onlyOwner {
        useNativeRouter[router] = true;
    }

    function removeNativeRouter(address router) external onlyOwner {
        useNativeRouter[router] = false;
    }
}