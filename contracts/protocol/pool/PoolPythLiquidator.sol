// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.12;

import {IExpressRelayFeeReceiver} from '../../interfaces/IExpressRelayFeeReceiver.sol';
import {LiquidationLogicPyth} from '../libraries/logic/LiquidationLogicPyth.sol';
import {Pool, IPoolAddressesProvider, DataTypes} from './Pool.sol';

contract PoolPythLiquidator is Pool, IExpressRelayFeeReceiver {
  uint256 public constant override POOL_REVISION = 0x6;

  constructor(IPoolAddressesProvider provider) Pool(provider) {}

  function init(IPoolAddressesProvider provider, address expressRelayAddress) external virtual {
    Pool.initialize(provider);
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

  function receiveAuctionProceedings(bytes calldata permissionKey) external payable {
    emit PoolReceivedETH(msg.sender, msg.value, permissionKey);
  }

  receive() external payable {}
}
