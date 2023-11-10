// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@morpho-blue-test/BaseTest.sol";
import {IMorphoSupplyCollateralCallback} from "@morpho-blue/interfaces/IMorphoCallbacks.sol";

contract CallbacksIntegrationTest is BaseTest, IMorphoSupplyCollateralCallback {
    using MathLib for uint256;
    using MorphoLib for IMorpho;
    using MorphoBalancesLib for IMorpho;
    using MarketParamsLib for MarketParams;

    // IMPLEMENTATION
    function onMorphoSupplyCollateral(uint256 amount, bytes memory data) external {
        require(msg.sender == address(morpho));
        bytes4 selector;
        (selector, data) = abi.decode(data, (bytes4, bytes));
        if (selector == this.testLeverageCallback.selector) {
            uint256 toBorrow = abi.decode(data, (uint256));

            // borrow the amount of the loan that the leveragors gave
            (uint256 amountBis,) = morpho.borrow(marketParams, toBorrow, 0, address(this), address(this));

            // CHEATCODE:
            // for the sake of the implementation, the following logic has been used.
            // In real use case, one would either swap the loan asset to the collat asset, or unwrap , stake and wrap
            // for a leverage of the type:
            // weth/wstETH
            // assume 1 loanTOken = 1 collatToken in value
            collateralToken.setBalance(address(this), amount); // be sure that amount is greater than the amountBis
                // value
            require(amount >= amountBis);
            collateralToken.approve(address(this), amount);
            // something as the following function could be defined
            // _wethToWSTETH(amountBis);
        }
    }

    // TEST

    function testLeverageCallback(uint256 loanAmount) public {
        loanAmount = bound(loanAmount, MIN_TEST_AMOUNT, MAX_TEST_AMOUNT);
        uint256 collateralAmount;
        (collateralAmount, loanAmount,) = _boundHealthyPosition(0, loanAmount, oracle.price());

        oracle.setPrice(ORACLE_PRICE_SCALE);

        // supplying 2 times the loanAmount such that there is liquidity into the market
        vm.startPrank(SUPPLIER);
        loanToken.setBalance(address(SUPPLIER), 2 * loanAmount);
        morpho.supply(marketParams, 2 * loanAmount, 0, address(SUPPLIER), hex"");
        vm.stopPrank();

        // let's call the callback function
        morpho.supplyCollateral(
            marketParams,
            collateralAmount, // the total collat that will be transfered from the user to the Blue market during the
                // callback mechanism
            address(this),
            // the loan amountcorresponds to what
            // will be borrowed from the market
            abi.encode(this.testLeverageCallback.selector, abi.encode(loanAmount))
        );

        assertGt(morpho.expectedSupplyAssets(marketParams, address(this)), 0, "no borrow"); // verify that the
            // position has
            // a borrow
            // assertEq(morpho.collateral(marketParams.id(), address(this)), collateralAmount, "no collateral");
    }
}
