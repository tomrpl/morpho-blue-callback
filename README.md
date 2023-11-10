TODOS:

- add 'require' to protect users
- encode the ONBEHALF such that snippets are only tool to leverage yourself

- EOA: prank the EOA and approve morpho, snippets on morpho

- unwrap stake wrap option

- comments with approval before!

- encode everything instead of the storage and decode it

/\*
Workflow Example for Leveraged Position on Morpho Protocol with wstETH and wETH:

Initial conditions:

- The user has 1 wstETH ready to supply on the Morpho Blue market as collateral.
- The user wants to leverage this position by borrowing 1 wETH against the supplied wstETH.

Steps:

1. User initiates a leveraged position by calling `supplyCollateral` on Morpho with `collateralAmount = 2 wstETH` and
   `bytes calldata data` encoding a call to `testLeverageCallback` with the desired `loanAmount` (e.g., 1 wETH).

2. As the `supplyCollateral` function is executed, since `data.length > 0`, it triggers the callback:
   `IMorphoSupplyCollateralCallback(msg.sender).onMorphoSupplyCollateral(2 wstETH, data);`

3. Inside `onMorphoSupplyCollateral`:
   a. The `selector` for `testLeverageCallback` is detected from `data`.
   b. The `toBorrow` amount (e.g., 1 wETH) is decoded from `data`.
   c. The contract itself, acting as the user, initiates a borrow transaction from Morpho for the `toBorrow` amount (1
   wETH).

Current virtual state of the transaction:

- The user has supplied 2 wstETH as collateral.
- The user has borrowed 1 wETH against this collateral.

4. (Intermediate step):
   A. The usual way would be to swap the borrowed assets against the collateral token.
   B. An elegant way in this very situation is the following:
   Since the user borrowed wETH, one could
   a. unwrap the weth,
   b. stake the eth unwrapped
   c. wrap the stETH staked

5. The user now resupplie as collateral the wstETH to maintain a healthy collateralization
   ratio. This is achieved by another call to `supplyCollateral` without any callback data:
   `morpho.supplyCollateral(marketParams, 1 wETH, address(this), hex"");`

End result:

- The user has effectively leveraged their position by supplying 2 wstETH as collateral and then resupplying the 1 wETH
  that was borrowed.

  - The user has a debt of 1 wETH borrowed against their supplied collateral of 2 wstETH.

  Note: Throughout the example, all the steps are happening in one atomic transaction due to the callback mechanism.

  Additional Notes:

- It's important that the contract has enough initial balance of wstETH (e.g., 2 wstETH) to supply as collateral and
  enough allowance for the Morpho contract to perform operations on the user's behalf.
  - Oracle prices, interest rates, and other market conditions have been assumed to be constant for simplicity.
  - This example assumes the Morpho protocol and the underlying tokens don't have transfer fees.
  - Fees, slippage, and other transaction costs are omitted in this example.
    \*/
