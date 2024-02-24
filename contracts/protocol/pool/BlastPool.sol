// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.12;

import {Pool, IPoolAddressesProvider} from './Pool.sol';
import {IBlast} from '../../interfaces/IBlast.sol';

contract BlastPool is Pool {
  constructor(IPoolAddressesProvider provider) Pool(provider) {}

  function init(IPoolAddressesProvider provider) external virtual {
    Pool.initialize(provider);
    IBlast blast = IBlast(0x4300000000000000000000000000000000000002);
    blast.configureClaimableGas();
  }

  function claimGas(address whom, address to) external onlyPoolAdmin {
    IBlast blast = IBlast(0x4300000000000000000000000000000000000002);
    blast.claimAllGas(whom, to);
  }
}
