// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.12;

import {VennFirewallConsumer} from '@ironblocks/firewall-consumer/contracts/consumers/VennFirewallConsumer.sol';
import {IExpressRelayFeeReceiver} from '../../interfaces/IExpressRelayFeeReceiver.sol';
import {LiquidationLogicPyth} from '../libraries/logic/LiquidationLogicPyth.sol';
import {Pool, IPoolAddressesProvider, DataTypes} from './Pool.sol';

contract PoolPythLiquidator is VennFirewallConsumer, Pool, IExpressRelayFeeReceiver {
  constructor(IPoolAddressesProvider provider) Pool(provider) {}

  function init(
    IPoolAddressesProvider provider,
    address expressRelayAddress
  ) external virtual firewallProtected {
    Pool.initialize(provider);
    expressRelay = expressRelayAddress;
  }

  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) public virtual override firewallProtected {
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
  function receiveAuctionProceedings(
    bytes calldata permissionKey
  ) external payable firewallProtected {
    emit PoolReceivedETH(msg.sender, msg.value, permissionKey);
  }

  receive() external payable {}
}
