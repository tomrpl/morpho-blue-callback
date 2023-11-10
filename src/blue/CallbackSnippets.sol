// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {SwapMock} from "@snippets/blue/mocks/SwapMock.sol";
import {IMorphoSupplyCollateralCallback, IMorphoRepayCallback} from "@morpho-blue/interfaces/IMorphoCallbacks.sol";

import {Id, IMorpho, MarketParams, Market} from "@morpho-blue/interfaces/IMorpho.sol";
import {SafeTransferLib, ERC20} from "@solmate/utils/SafeTransferLib.sol";
import {MathLib} from "@morpho-blue/libraries/MathLib.sol";
import {MorphoLib} from "@morpho-blue/libraries/periphery/MorphoLib.sol";
import {MorphoBalancesLib} from "@morpho-blue/libraries/periphery/MorphoBalancesLib.sol";
import {MarketParamsLib} from "@morpho-blue/libraries/MarketParamsLib.sol";

// Better: put the marketParams
// data needed for the callback are better handled if we encode them in the onMorpho functions
contract CallbacksSnippets is IMorphoSupplyCollateralCallback, IMorphoRepayCallback {
    using MathLib for uint256;
    using MorphoLib for IMorpho;
    // using MorphoBalancesLib for IMorpho;
    using MarketParamsLib for MarketParams;

    IMorpho public immutable morpho;
    SwapMock swapMock;
    MarketParams marketParams;

    constructor(address morphoAddress) {
        morpho = IMorpho(morphoAddress);
        // swapMock = new SwapMock(address(collateralToken), address(loanToken), address(oracle));
    }

    /* 
    
    Callbacks
    remember that at a given market, one can leverage itself up to 1/1-LLTV,
    leverageFactor so for an LLTV of 80% -> 5 is the max leverage factor
    loanLeverageFactor max loanLeverageFactor would have to be on LLTV * leverageFactor to be safe
    
    */

    function onMorphoSupplyCollateral(uint256 amount, bytes memory data) external {
        require(msg.sender == address(morpho));
        bytes4 selector;
        (selector, data) = abi.decode(data, (bytes4, bytes));
        if (selector == this.leverageMe.selector) {
            uint256 toBorrow = abi.decode(data, (uint256));
            (uint256 amountBis,) = morpho.borrow(marketParams, toBorrow, 0, address(this), address(this));
            ERC20(marketParams.collateralToken).approve(address(swapMock), amount);

            // Logic to Implement. Following example is a swap, could be a 'unwrap + stake + wrap staked' for
            // wETH(wstETH) Market
            swapMock.swapLoanToCollat(amountBis);
        }
    }

    function onMorphoRepay(uint256 amount, bytes memory data) external {
        require(msg.sender == address(morpho));
        bytes4 selector;
        (selector, data) = abi.decode(data, (bytes4, bytes));
        if (selector == this.deLeverageMe.selector) {
            uint256 toWithdraw = abi.decode(data, (uint256));
            morpho.withdrawCollateral(marketParams, toWithdraw, address(this), address(this));
            ERC20(marketParams.loanToken).approve(address(morpho), amount);
            swapMock.swapCollatToLoan(toWithdraw);
        }
    }

    // leverage function
    function leverageMe(
        uint256 leverageFactor,
        uint256 loanLeverageFactor,
        uint256 initialCollateral,
        SwapMock _swapMock,
        MarketParams memory _marketParams
    ) public {
        _setSwapMock(_swapMock);
        _setMarketParams(_marketParams);

        uint256 collateralAssets = initialCollateral * leverageFactor;
        uint256 loanAmount = initialCollateral * loanLeverageFactor;

        _approveMaxTo(address(marketParams.collateralToken), address(this));

        morpho.supplyCollateral(
            marketParams, collateralAssets, address(this), abi.encode(this.leverageMe.selector, abi.encode(loanAmount))
        );
    }

    // deleverage function
    function deLeverageMe(
        uint256 leverageFactor,
        uint256 loanLeverageFactor,
        uint256 initialCollateral,
        SwapMock _swapMock,
        MarketParams memory _marketParams
    ) public returns (uint256 amountRepayed) {
        // might be redundant
        _setSwapMock(_swapMock);
        _setMarketParams(_marketParams);

        uint256 collateralAssets = initialCollateral * leverageFactor;
        uint256 loanAmount = initialCollateral * loanLeverageFactor;

        _approveMaxTo(address(marketParams.collateralToken), address(this));

        (amountRepayed,) = morpho.repay(
            marketParams,
            loanAmount,
            0,
            address(this),
            abi.encode(this.deLeverageMe.selector, abi.encode(collateralAssets))
        );
    }

    function _approveMaxTo(address asset, address spender) internal {
        if (ERC20(asset).allowance(address(this), spender) == 0) {
            ERC20(asset).approve(spender, type(uint256).max);
        }
    }

    /*
    The following implementation regarding the swap mocked has been done for educationnal purpose
    the swap mock is giving back, thanks to the orace of the market, the exact value in terms of amount between a
    collateral and a loan token
    
    One should be aware that has to be taken into account on potential swap:
     1. slippage
     2. fees
    */

    function _setSwapMock(SwapMock _swapMock) public {
        swapMock = _swapMock;
    }

    function _setMarketParams(MarketParams memory _marketParams) public {
        marketParams = _marketParams;
    }
}
