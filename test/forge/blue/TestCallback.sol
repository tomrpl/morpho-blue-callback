// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

// import "@morpho-blue-test/BaseTest.sol";

// import {CallbackSnippets} from "@snippets/blue/Callback.sol";

// contract CallbacksIntegrationTest is BaseTest {
//     using MathLib for uint256;
//     using MorphoLib for IMorpho;
//     using MarketParamsLib for MarketParams;

//     CallbackSnippets public snippets;

//     function setUp() public virtual override {
//         super.setUp();
//         snippets = new CallbackSnippets(address(morpho)); // todos add the addres of WETH, lido, wsteth
//     }

//     function testLeverageCallback(uint256 loanAmount) public {
//         loanAmount = bound(loanAmount, MIN_TEST_AMOUNT, MAX_TEST_AMOUNT);
//         uint256 collateralAmount;
//         (collateralAmount, loanAmount,) = _boundHealthyPosition(0, loanAmount, oracle.price());

//         oracle.setPrice(ORACLE_PRICE_SCALE);

//         // supplying 2 times the loanAmount
//         vm.startPrank(SUPPLIER);
//         loanToken.setBalance(address(this), 2 * loanAmount);
//         morpho.supply(marketParams, 2 * loanAmount, 0, address(this), hex"");
//         vm.stopPrank();

//         snippets.leverageMe(5, collateralAmount, marketParams);

//         assertGt(morpho.borrowShares(marketParams.id(), address(snippets)), 0, "no borrow");
//         assertEq(morpho.collateral(marketParams.id(), address(snippets)), 0, "no withdraw collateral");
//     }

//     // function testFlashActions(uint256 loanAmount) public {
//     //     loanAmount = bound(loanAmount, MIN_TEST_AMOUNT, MAX_TEST_AMOUNT);
//     //     uint256 collateralAmount;
//     //     (collateralAmount, loanAmount,) = _boundHealthyPosition(0, loanAmount, oracle.price());

//     //     oracle.setPrice(ORACLE_PRICE_SCALE);

//     //     loanToken.setBalance(address(this), loanAmount);
//     //     morpho.supply(marketParams, loanAmount, 0, address(this), hex"");

//     //     morpho.supplyCollateral(
//     //         marketParams,
//     //         collateralAmount,
//     //         address(this),
//     //         abi.encode(this.testFlashActions.selector, abi.encode(loanAmount))
//     //     );
//     //     assertGt(morpho.borrowShares(marketParams.id(), address(this)), 0, "no borrow");

//     //     morpho.repay(
//     //         marketParams,
//     //         loanAmount,
//     //         0,
//     //         address(this),
//     //         abi.encode(this.testFlashActions.selector, abi.encode(collateralAmount))
//     //     );
//     //     assertEq(morpho.collateral(marketParams.id(), address(this)), 0, "no withdraw collateral");
//     // }

//     // function testSupplyCollateralCallback(uint256 amount) public {
//     //     amount = bound(amount, 1, MAX_COLLATERAL_ASSETS);

//     //     collateralToken.setBalance(address(this), amount);
//     //     collateralToken.approve(address(morpho), 0);

//     //     vm.expectRevert();
//     //     morpho.supplyCollateral(marketParams, amount, address(this), hex"");
//     //     morpho.supplyCollateral(
//     //         marketParams, amount, address(this), abi.encode(this.testSupplyCollateralCallback.selector, hex"")
//     //     );
//     // }
// }
