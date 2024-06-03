// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IExpressRelayFeeReceiver} from '../../interfaces/IExpressRelayFeeReceiver.sol';
import {L2Pool} from './L2Pool.sol';
import {LiquidationLogicPyth} from '../libraries/logic/LiquidationLogicPyth.sol';
import {IPoolAddressesProvider, DataTypes} from './Pool.sol';

/**
 * @title L2PoolPythLiquidator
 * @author Aave
 * @notice Calldata optimized extension of the Pool contract allowing users to pass compact calldata representation
 * to reduce transaction costs on rollups.
 */
contract L2PoolPythLiquidator is L2Pool, IExpressRelayFeeReceiver {
  /**
   * @dev Constructor.
   * @param provider The address of the PoolAddressesProvider contract
   */
  constructor(IPoolAddressesProvider provider) L2Pool(provider) {
    // Intentionally left blank
  }

  function init(IPoolAddressesProvider provider, address expressRelayAddress) external virtual {
    initialize(provider);
    expressRelay = expressRelayAddress;
  }

  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) public virtual override {
    LiquidationLogicPyth.executeLiquidationCall(
      _reserves,
      _reservesList,
      _usersConfig,
      _eModeCategories,
      DataTypes.ExecuteLiquidationCallParams({
        reservesCount: _reservesCount,
        debtToCover: debtToCover,
        collateralAsset: collateralAsset,
        debtAsset: debtAsset,
        user: user,
        receiveAToken: receiveAToken,
        priceOracle: ADDRESSES_PROVIDER.getPriceOracle(),
        userEModeCategory: _usersEModeCategory[user],
        priceOracleSentinel: ADDRESSES_PROVIDER.getPriceOracleSentinel()
      }),
      expressRelay
    );
  }

  /**
   * @notice receiveAuctionProceedings function - receives native token from the express relay
   * @param permissionKey: permission key that was used for the auction
   */
  function receiveAuctionProceedings(bytes calldata permissionKey) external payable {
    emit PoolReceivedETH(msg.sender, msg.value, permissionKey);
  }

  receive() external payable {}
}
