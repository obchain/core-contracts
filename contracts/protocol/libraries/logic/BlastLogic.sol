// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.12;

import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {IBlast} from '../../../interfaces/IBlast.sol';

/**
 * @title BlastLogic library
 * @author ZeroLend
 * @notice Implements the logic for updating blast logic
 */
library BlastLogic {
  using ReserveLogic for DataTypes.ReserveData;

  function compoundYield(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    address asset
  ) external {
    // if we are dealing with WETH or USDB; then claim the yield and cumulate to the liquidity index
    if (
      asset != 0x4200000000000000000000000000000000000023 &&
      asset != 0x4200000000000000000000000000000000000022
    ) return;

    DataTypes.ReserveData storage reserve = reservesData[asset];
    DataTypes.ReserveCache memory reserveCache = reserve.cache();

    reserve.updateState(reserveCache);

    IBlast blast = IBlast(0x4300000000000000000000000000000000000002);

    uint256 blastYield = blast.claimAllYield(
      reserveCache.aTokenAddress,
      reserveCache.aTokenAddress
    );

    // add new yield to the liquidity index
    reserveCache.nextLiquidityIndex = reserve.cumulateToLiquidityIndex(
      IERC20(reserveCache.aTokenAddress).totalSupply(),
      blastYield
    );

    reserve.updateInterestRates(reserveCache, asset, blastYield, 0);
  }
}
