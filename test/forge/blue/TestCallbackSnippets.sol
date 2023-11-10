// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@morpho-blue-test/BaseTest.sol";
import {SwapMock} from "@snippets/blue/mocks/SwapMock.sol";
import {CallbacksSnippets} from "@snippets/blue/CallbackSnippets.sol";

contract CallbacksIntegrationTest is BaseTest {
    using MathLib for uint256;
    using MorphoLib for IMorpho;
    using MorphoBalancesLib for IMorpho;
    using MarketParamsLib for MarketParams;

    SwapMock internal swapMock;

    CallbacksSnippets public snippets;

    function setUp() public virtual override {
        super.setUp();
        swapMock = new SwapMock(address(collateralToken), address(loanToken), address(oracle));
        snippets = new CallbacksSnippets(address(morpho)); // todos add the addres of WETH, lido, wsteth
    }

    function testLeverageMe(uint256 collateralInitAmount) public {
        // INITIALISATION

        uint256 leverageFactor = 4; // nb to set
        uint256 loanLeverageFactor = 3; // max here would be 3.2 = 0.8 * leverageFactor

        collateralInitAmount = bound(collateralInitAmount, MIN_TEST_AMOUNT, MAX_TEST_AMOUNT / leverageFactor);

        collateralToken.setBalance(address(snippets), collateralInitAmount);

        uint256 collateralAmount = collateralInitAmount * leverageFactor;

        oracle.setPrice(ORACLE_PRICE_SCALE);

        // supplying enough liquidity in the market
        vm.startPrank(SUPPLIER);
        loanToken.setBalance(address(SUPPLIER), collateralAmount);
        morpho.supply(marketParams, collateralAmount, 0, address(SUPPLIER), hex"");
        vm.stopPrank();

        // approve the swap contract
        vm.startPrank(address(snippets));
        loanToken.approve(address(morpho), type(uint256).max);
        loanToken.approve(address(swapMock), type(uint256).max);
        collateralToken.approve(address(morpho), type(uint256).max);
        collateralToken.approve(address(swapMock), type(uint256).max);
        vm.stopPrank();

        // Compute LoanAmount
        uint256 loanAmount = collateralInitAmount * loanLeverageFactor;
        snippets.leverageMe(leverageFactor, loanLeverageFactor, collateralInitAmount, swapMock, marketParams);
        // let's call the callback function

        assertGt(morpho.borrowShares(marketParams.id(), address(snippets)), 0, "no borrow");
        assertEq(morpho.collateral(marketParams.id(), address(snippets)), collateralAmount, "no collateral");
        assertEq(morpho.expectedBorrowAssets(marketParams, address(snippets)), loanAmount, "no collateral");
    }

    function testDeLeverageMe(uint256 collateralInitAmount) public {
        /// same as testLeverageMe

        uint256 leverageFactor = 4; // nb to set
        uint256 loanLeverageFactor = 3; // max here would be 3.2 = 0.8 * leverageFactor

        collateralInitAmount = bound(collateralInitAmount, MIN_TEST_AMOUNT, MAX_TEST_AMOUNT / leverageFactor);

        collateralToken.setBalance(address(snippets), collateralInitAmount);

        uint256 collateralAmount = collateralInitAmount * leverageFactor;

        oracle.setPrice(ORACLE_PRICE_SCALE);

        // supplying enough liquidity in the market
        vm.startPrank(SUPPLIER);
        loanToken.setBalance(address(SUPPLIER), collateralAmount);
        morpho.supply(marketParams, collateralAmount, 0, address(SUPPLIER), hex"");
        vm.stopPrank();

        // approve the swap contract
        vm.startPrank(address(snippets));
        loanToken.approve(address(morpho), type(uint256).max);
        loanToken.approve(address(swapMock), type(uint256).max);
        collateralToken.approve(address(morpho), type(uint256).max);
        collateralToken.approve(address(swapMock), type(uint256).max);
        vm.stopPrank();

        // Compute LoanAmount
        uint256 loanAmount = collateralInitAmount * loanLeverageFactor;
        snippets.leverageMe(leverageFactor, loanLeverageFactor, collateralInitAmount, swapMock, marketParams);
        // let's call the callback function

        assertGt(morpho.borrowShares(marketParams.id(), address(snippets)), 0, "no borrow");
        assertEq(morpho.collateral(marketParams.id(), address(snippets)), collateralAmount, "no collateral");
        assertEq(morpho.expectedBorrowAssets(marketParams, address(snippets)), loanAmount, "no collateral");

        /// end of testLeverageMe
        uint256 amountRepayed =
            snippets.deLeverageMe(leverageFactor, loanLeverageFactor, collateralInitAmount, swapMock, marketParams);

        assertEq(morpho.borrowShares(marketParams.id(), address(snippets)), 0, "no borrow");
        assertEq(amountRepayed, loanAmount, "no repaid");
    }
}
