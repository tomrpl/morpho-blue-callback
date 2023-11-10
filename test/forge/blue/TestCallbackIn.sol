// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@morpho-blue-test/BaseTest.sol";
import {IMorphoSupplyCollateralCallback, IMorphoRepayCallback} from "@morpho-blue/interfaces/IMorphoCallbacks.sol";
import {SwapMock} from "@snippets/blue/mocks/SwapMock.sol";

contract CallbacksIntegrationTest is BaseTest, IMorphoSupplyCollateralCallback, IMorphoRepayCallback {
    using MathLib for uint256;
    using MorphoLib for IMorpho;
    using MorphoBalancesLib for IMorpho;
    using MarketParamsLib for MarketParams;

    SwapMock internal swapMock;

    function setUp() public virtual override {
        super.setUp();
        swapMock = new SwapMock(address(collateralToken), address(loanToken), address(oracle));
    }

    // IMPLEMENTATION

    function onMorphoSupplyCollateral(uint256 amount, bytes memory data) external {
        require(msg.sender == address(morpho));
        bytes4 selector;
        (selector, data) = abi.decode(data, (bytes4, bytes));
        if (selector == this.testLeverageCallback.selector) {
            uint256 toBorrow = abi.decode(data, (uint256));
            (uint256 amountBis,) = morpho.borrow(marketParams, toBorrow, 0, address(this), address(this));
            collateralToken.approve(address(this), amount);

            // Logic to Implement. Following example is a swap, could be a 'unwrap + stake + wrap staked' for
            // wETH(wstETH) Market
            swapMock.swapLoanToCollat(amountBis);
        }
    }

    function onMorphoRepay(uint256 amount, bytes memory data) external {
        require(msg.sender == address(morpho));
        bytes4 selector;
        (selector, data) = abi.decode(data, (bytes4, bytes));
        if (selector == this.testLeverageCallback.selector) {
            uint256 toWithdraw = abi.decode(data, (uint256));
            morpho.withdrawCollateral(marketParams, toWithdraw, address(this), address(this));
            loanToken.approve(address(morpho), amount);
            swapMock.swapCollatToLoan(toWithdraw);
        }
    }

    // TEST

    function testLeverageCallback(uint256 collateralInitAmount) public {
        // INITIALISATION

        uint256 leverageFactor = 4; // nb to set
        uint256 loanLeverageFactor = 3; // max here would be 3.2 = 0.8 * leverageFactor

        collateralInitAmount = bound(collateralInitAmount, MIN_TEST_AMOUNT, MAX_TEST_AMOUNT / leverageFactor);

        collateralToken.setBalance(address(this), collateralInitAmount);

        uint256 collateralAmount = collateralInitAmount * leverageFactor; // this is targeted leverage
        // (collateralAmount, loanAmount,) = _boundHealthyPosition(0, loanAmount, oracle.price());

        oracle.setPrice(ORACLE_PRICE_SCALE);

        // supplying enough liquidity in the market
        vm.startPrank(SUPPLIER);
        loanToken.setBalance(address(SUPPLIER), collateralAmount);
        morpho.supply(marketParams, collateralAmount, 0, address(SUPPLIER), hex"");
        vm.stopPrank();

        // approve the swap contract
        loanToken.approve(address(swapMock), type(uint256).max);

        // Compute LoanAmount
        uint256 loanAmount = collateralInitAmount * loanLeverageFactor;

        // let's call the callback function
        morpho.supplyCollateral(
            marketParams,
            collateralAmount,
            address(this),
            abi.encode(this.testLeverageCallback.selector, abi.encode(loanAmount))
        );

        assertGt(morpho.borrowShares(marketParams.id(), address(this)), 0, "no borrow");
        assertEq(morpho.collateral(marketParams.id(), address(this)), collateralAmount, "no collateral");
        assertEq(morpho.expectedBorrowAssets(marketParams, address(this)), loanAmount, "no collateral");
    }

    function testLeverageThenDeleverageCallback(uint256 collateralInitAmount) public {
        /// ///  PURE COPY OF PREVIOUS TEST, DO NOT TOUCH
        // INITIALISATION

        uint256 leverageFactor = 4; // nb to set
        uint256 loanLeverageFactor = 3; // max here would be 3.2 = 0.8 * leverageFactor

        collateralInitAmount = bound(collateralInitAmount, MIN_TEST_AMOUNT, MAX_TEST_AMOUNT / leverageFactor);

        collateralToken.setBalance(address(this), collateralInitAmount);

        uint256 collateralAmount = collateralInitAmount * leverageFactor;
        oracle.setPrice(ORACLE_PRICE_SCALE);

        // supplying enough liquidity in the market
        vm.startPrank(SUPPLIER);
        loanToken.setBalance(address(SUPPLIER), collateralAmount);
        morpho.supply(marketParams, collateralAmount, 0, address(SUPPLIER), hex"");
        vm.stopPrank();

        // approve the swap contract
        loanToken.approve(address(swapMock), type(uint256).max);

        // Compute LoanAmount
        uint256 loanAmount = collateralInitAmount * loanLeverageFactor;

        // let's call the callback function
        morpho.supplyCollateral(
            marketParams,
            collateralAmount,
            address(this),
            abi.encode(this.testLeverageCallback.selector, abi.encode(loanAmount))
        );

        assertGt(morpho.borrowShares(marketParams.id(), address(this)), 0, "no borrow");
        assertEq(morpho.collateral(marketParams.id(), address(this)), collateralAmount, "no collateral");
        assertEq(morpho.expectedBorrowAssets(marketParams, address(this)), loanAmount, "no collateral");

        /// END OF PURE COPY OF PREVIOUS TEST

        collateralToken.approve(address(swapMock), type(uint256).max);
        (uint256 amountRepayed,) = morpho.repay(
            marketParams,
            loanAmount,
            0,
            address(this),
            abi.encode(this.testLeverageCallback.selector, abi.encode(collateralAmount))
        );

        assertEq(morpho.borrowShares(marketParams.id(), address(this)), 0, "no borrow");
        assertEq(amountRepayed, loanAmount, "no repaid");
    }
}
