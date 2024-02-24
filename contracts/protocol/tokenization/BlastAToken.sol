// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.12;

import {AToken, IAaveIncentivesController, IPool} from './AToken.sol';
import {IBlast} from '../../interfaces/IBlast.sol';
import {IBlastRebasingERC20, BlastERC20YieldMode} from '../../interfaces/IBlastRebasingERC20.sol';

contract BlastAToken is AToken {
  constructor(IPool pool) AToken(pool) {}

  function initialize(
    IPool initializingPool,
    address treasury,
    address underlyingAsset,
    IAaveIncentivesController incentivesController,
    uint8 aTokenDecimals,
    string calldata aTokenName,
    string calldata aTokenSymbol,
    bytes calldata params
  ) public virtual override {
    AToken.initialize(
      initializingPool,
      treasury,
      underlyingAsset,
      incentivesController,
      aTokenDecimals,
      aTokenName,
      aTokenSymbol,
      params
    );

    IBlast blast = IBlast(0x4300000000000000000000000000000000000002);
    IBlastRebasingERC20(underlyingAsset).configure(BlastERC20YieldMode.CLAIMABLE);
    blast.configureGovernor(address(initializingPool));
  }
}
