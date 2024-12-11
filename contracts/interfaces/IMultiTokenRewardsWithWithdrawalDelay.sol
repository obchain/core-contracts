// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.21;

// ███████╗███████╗██████╗  ██████╗
// ╚══███╔╝██╔════╝██╔══██╗██╔═══██╗
//   ███╔╝ █████╗  ██████╔╝██║   ██║
//  ███╔╝  ██╔══╝  ██╔══██╗██║   ██║
// ███████╗███████╗██║  ██║╚██████╔╝
// ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝

// Website: https://zerolend.xyz
// Discord: https://discord.gg/zerolend
// Twitter: https://twitter.com/zerolendxyz

import {IMultiStakingRewardsERC4626} from './IMultiStakingRewardsERC4626.sol';

interface IMultiTokenRewardsWithWithdrawalDelay is IMultiStakingRewardsERC4626 {
  event WithdrawalQueueUpdated(
    uint256 indexed amt,
    uint256 indexed unlockTime,
    address indexed caller
  );

  function queueWithdrawal(uint256 shares) external;

  function withdrawalDelay() external view returns (uint256);

  function withdrawalAmount(address who) external view returns (uint256);

  function withdrawalTimestamp(address who) external view returns (uint256);

  function cancelWithdrawal() external;
}
