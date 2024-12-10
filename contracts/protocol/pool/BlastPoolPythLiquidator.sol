// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IExpressRelayFeeReceiver} from '../../interfaces/IExpressRelayFeeReceiver.sol';
import {BlastPool} from './BlastPool.sol';
import {LiquidationLogicPyth} from '../libraries/logic/LiquidationLogicPyth.sol';
import {IPoolAddressesProvider, DataTypes} from './Pool.sol';

contract BlastPoolPythLiquidator is BlastPool, IExpressRelayFeeReceiver {
  /**
   * @dev Constructor.
   * @param provider The address of the PoolAddressesProvider contract
   */
  constructor(IPoolAddressesProvider provider) BlastPool(provider) {
    // Intentionally left blank
  }

  function init(IPoolAddressesProvider provider, address expressRelayAddress) external virtual {
    init(provider);
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
