/\*
Workflow Example for setting up a
Leveraged Position
on Morpho Protocol with wstETH and wETH:

Initial conditions:

- The user has 2 wstETH ready to supply on the Morpho Blue market as collateral.
- The user wants to leverage this position by borrowing some wETH against the to be supplied wstETH.

Assume that the market is with a 90% LTV with enough liquidity. and that 1 wstETH = 1 WETH //todo to modify

Steps:

1. User initiates a leveraged position by calling `supplyCollateral` on Morpho with `collateralAmount = 10 wstETH` and
   `bytes calldata data` encoding a call to `testLeverageCallback` with the desired `loanAmount` (max is 9 wETH before being unhealthy), let's set oneself up to 8 WETH so the user is safe at the end of the transaction.

2. As the `supplyCollateral` function is executed, since `data.length > 0`, it triggers the callback:
   `IMorphoSupplyCollateralCallback(msg.sender).onMorphoSupplyCollateral(10 wstETH, data);`

3. Inside `onMorphoSupplyCollateral`:
   a. The `selector` for `testLeverageCallback` is detected from `data`.
   b. The `toBorrow` amount (e.g., 8 wETH) is decoded from `data`.
   c. The contract itself, acting as the user, initiates a borrow transaction from Morpho for the `toBorrow` amount (8
   wETH).

4. Now we have to get those 8 wETH into wstETH:
   (Intermediate step):
   A. The usual way would be to swap the borrowed assets against the collateral token.
   or
   B. An elegant way in this very situation is the following:
   Since the user borrowed wETH, one could (contrcats need to be payable for handling ETH)

   - unwrap the weth,
   - stake the eth unwrapped
   - wrap the stETH staked
   - approve morpho to use your wstETH (cn be done before)

5. By the end of the transaction,

`IERC20(marketParams.collateralToken).safeTransferFrom(msg.sender, address(this), assets);`

- The equivalent of the 8 wEth Borrowed transformed are bringing approx 8 wstETH
- The user had 2 wstETH at the beginning
- the safeTransfer is triggered, supplying the 10 wstETH into the market as collateral.

End result:

- The user has effectively leveraged their position by supplying approx: 2+8 wstETH as collateral, borrowed 8 wETH and gets a leverage position of x5.

  - The user has a debt of 1 wETH borrowed against their supplied collateral of 2 wstETH.

  Note: Throughout the example, all the steps are happening in one atomic transaction due to the callback mechanism.

  Additional Notes:

- It's important that the contract has enough initial balance of wstETH (e.g., 2 wstETH) to supply as collateral and
  enough allowance for the Morpho contract to perform operations on the user's behalf.
  - Oracle prices, interest rates, and other market conditions have been assumed to be constant for simplicity.
  - This example assumes the Morpho protocol and the underlying tokens don't have transfer fees.
  - Fees, slippage, and other transaction costs are omitted in this example.
    \*/
