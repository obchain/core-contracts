// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

enum BlastERC20YieldMode {
  AUTOMATIC,
  VOID,
  CLAIMABLE
}

interface IBlastRebasingERC20 {
  // changes the yield mode of the caller and update the balance
  // to reflect the configuration
  function configure(BlastERC20YieldMode) external returns (uint256);

  // "claimable" yield mode accounts can call this this claim their yield
  // to another address
  function claim(address recipient, uint256 amount) external returns (uint256);

  // read the claimable amount for an account
  function getClaimableAmount(address account) external view returns (uint256);
}
