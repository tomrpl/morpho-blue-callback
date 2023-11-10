// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

// import {Id, IMorpho, MarketParams, Market} from "@morpho-blue/interfaces/IMorpho.sol";
// import {SafeTransferLib, ERC20} from "@solmate/utils/SafeTransferLib.sol";
// import {MathLib} from "@morpho-blue/libraries/MathLib.sol";

// TODO place interfaces in a folder
// mimic the bundler behavior for such purpose

// interface IMorphoSupplyCollateralCallback {
//     /// @notice Callback called when a supply occurs.
//     /// @dev The callback is called only if data is not empty.
//     /// @param assets The amount of supplied assets.
//     /// @param data Arbitrary data passed to the `supply` function.
//     function onMorphoSupplyCollateral(uint256 assets, bytes calldata data) external;
// }

// interface IWETH {
//     function withdraw(uint256 wad) external;
// }

// interface ILido {
//     function submit(address referral) external payable returns (uint256);
// }

// interface IwstETH {
//     function wrap(uint256 _stETHAmount) external returns (uint256);
// }

// contract CallbackSnippets is IMorphoSupplyCollateralCallback {
//     IWETH public weth;
//     ILido public lido;
//     IwstETH public wstETH;

//     using SafeTransferLib for ERC20;
//     using MathLib for uint256;

//     IMorpho public immutable morpho;
//     MarketParams marketParams;

//     /// @notice Constructs the contract.
//     /// @param morphoAddress The address of the Morpho Blue contract.
//     constructor(address morphoAddress, address _weth, address _lido, address _wstETH) {
//         morpho = IMorpho(morphoAddress);
//         weth = IWETH(_weth);
//         lido = ILido(_lido);
//         wstETH = IwstETH(_wstETH);
//     }

//     function _setMarketParams(MarketParams memory _marketParams) public {
//         marketParams = _marketParams;
//     }

//     // @amount corresponds to the amount that will be transfered from the snippets to the Morpho Blue market
//     function onMorphoSupplyCollateral(uint256 amount, bytes memory data) external {
//         require(msg.sender == address(morpho));
//         bytes4 selector;
//         (selector, data) = abi.decode(data, (bytes4, bytes));
//         if (selector == this.leverageMe.selector) {
//             uint256 toBorrow = abi.decode(data, (uint256));

//             // TODOS (SAFE) APPROVE THE swtETH, wsteth
//             // change ERC20 to type of stETH/wstETH
//             // change amount to typeUINT256?
//             ERC20(marketParams.loanToken).safeApprove(address(morpho), amount);
//             _approveMaxTo(marketParams.collateralToken, address(this));

//             (uint256 amountBis,) = morpho.borrow(marketParams, toBorrow, 0, address(this), address(this));

//             _wethToWSTETH(amountBis);
//         }
//     }

//     function leverageMe(uint256 times, uint256 collateralAmount, MarketParams memory __marketParams) external payable
// {
//         _setMarketParams(__marketParams);

//         uint256 loanAmount = collateralAmount.wMulDown(times);

//         _approveMaxTo(marketParams.collateralToken, address(this));

//         morpho.supplyCollateral(
//             marketParams, collateralAmount, address(this), abi.encode(this.leverageMe.selector,
// abi.encode(loanAmount))
//         );
//     }

//     function _wethToWSTETH(uint256 assets) internal returns (uint256 wstETHAssets) {
//         // Step 1: Unwrap WETH to ETH
//         weth.withdraw(assets);

//         // Step 2: Stake ETH for stETH
//         // The `submit` function sends the entire ETH balance, so ensure you only have the desired ETH amount
//         uint256 stETHAssets = lido.submit{value: assets}(address(this));

//         // Step 3: Wrap stETH to wstETH
//         // Assuming you have the necessary approvals set up to spend stETH
//         wstETHAssets = wstETH.wrap(stETHAssets);
//     }

//     function _approveMaxTo(address asset, address spender) internal {
//         if (ERC20(asset).allowance(address(this), spender) == 0) {
//             ERC20(asset).safeApprove(spender, type(uint256).max);
//         }
//         // TODOS: add the approval of stETH
//     }

//     receive() external payable {}
// }
