// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.12;

import {AToken, IAaveIncentivesController, IPool} from './AToken.sol';
import {IBlast, IBlastRebasingERC20, YieldMode} from '../../interfaces/IBlast.sol';
import {IBlastAToken} from '../../interfaces/IBlastAToken.sol';
import {IACLManager} from '../../interfaces/IACLManager.sol';

contract BlastAToken is AToken, IBlastAToken {
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
    IBlastRebasingERC20(underlyingAsset).configure(YieldMode.CLAIMABLE);
    blast.configureGovernor(address(initializingPool));
  }

  function claimYield(address to) public virtual override onlyPool returns (uint256) {
    IACLManager aclManager = IACLManager(_addressesProvider.getACLManager());
    require(aclManager.isPoolAdmin(msg.sender) || _msgSender() == address(POOL), '!user');

    IBlastRebasingERC20 erc20 = IBlastRebasingERC20(_underlyingAsset);
    uint256 claimable = erc20.getClaimableAmount(address(this));
    erc20.claim(to, claimable);
    return claimable;
  }
}
