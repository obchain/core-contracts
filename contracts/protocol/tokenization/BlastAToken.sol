// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.12;

import {AToken, IAaveIncentivesController, IPool} from './AToken.sol';
import {IBlast, IBlastRebasingERC20, YieldMode} from '../../interfaces/IBlast.sol';
import {IBlastAToken} from '../../interfaces/IBlastAToken.sol';
import {IACLManager} from '../../interfaces/IACLManager.sol';

interface IBlastPoints {
  function configurePointsOperator(address operator) external;
}

contract BlastAToken is AToken, IBlastAToken {
  constructor(IPool pool) AToken(pool) {}

  function getRevision() internal pure virtual override returns (uint256) {
    return 0x2;
  }

  function claimYield(address to) public virtual override returns (uint256) {
    IACLManager aclManager = IACLManager(_addressesProvider.getACLManager());
    require(aclManager.isPoolAdmin(msg.sender) || _msgSender() == address(POOL), '!user');

    IBlastRebasingERC20 erc20 = IBlastRebasingERC20(_underlyingAsset);
    uint256 claimable = erc20.getClaimableAmount(address(this));
    return erc20.claim(to, claimable);
  }

  function configureGovernor(address governor) public override onlyPoolAdmin {
    IBlast blast = IBlast(0x4300000000000000000000000000000000000002);
    IBlastRebasingERC20(_underlyingAsset).configure(YieldMode.CLAIMABLE);
    blast.configureGovernor(governor);
  }

  function configurePointsOperator(address pointsAddr, address who) public override onlyPoolAdmin {
    IBlastPoints(pointsAddr).configurePointsOperator(who);
  }
}
