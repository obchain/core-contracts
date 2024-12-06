// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.12;

import {VennFirewallConsumer} from '@ironblocks/firewall-consumer/contracts/consumers/VennFirewallConsumer.sol';
import {Pool, IPoolAddressesProvider, DataTypes} from './Pool.sol';
import {BlastLogic} from '../libraries/logic/BlastLogic.sol';
import {IBlast, IBlastRebasingERC20} from '../../interfaces/IBlast.sol';
import {IBlastAToken} from '../../interfaces/IBlastAToken.sol';

contract BlastPool is VennFirewallConsumer, Pool {
  constructor(IPoolAddressesProvider provider) Pool(provider) {}

  function init(IPoolAddressesProvider provider) public virtual firewallProtected {
    Pool.initialize(provider);
    IBlast blast = IBlast(0x4300000000000000000000000000000000000002);
    blast.configureClaimableGas();
  }

  function claimGas(address whom, address to) external onlyPoolAdmin firewallProtected {
    IBlast blast = IBlast(0x4300000000000000000000000000000000000002);
    blast.claimAllGas(whom, to);
  }

  function claimERC20yields(address token, address dest) external onlyPoolAdmin firewallProtected {
    IBlastAToken(token).claimYield(dest);
  }

  function compoundYields(address reserve) external onlyPoolAdmin firewallProtected {
    BlastLogic.compoundYield(_reserves, reserve);
  }
}
