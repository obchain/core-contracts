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

import {ISafetyPool} from '../../interfaces/ISafetyPool.sol';
import {IOmnichainStaking} from '../../interfaces/IOmnichainStaking.sol';
import {MultiStakingRewardsERC4626} from '../utils/MultiStakingRewardsERC4626.sol';
import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';

contract SafetyPool is MultiStakingRewardsERC4626, ISafetyPool {
  /// @inheritdoc ISafetyPool
  bytes32 public immutable MANAGER_ROLE = keccak256('MANAGER_ROLE');

  function initialize(
    address _stablecoin,
    address _governance,
    address _rewardToken1,
    address _rewardToken2,
    uint256 _rewardsDuration,
    address _stakingBoost
  ) external initializer {
    __MultiStakingRewardsERC4626_init(
      'Staked ZAI',
      'sZAI',
      _stablecoin,
      86_400 * 21,
      _governance,
      _rewardToken1,
      _rewardToken2,
      _rewardsDuration,
      _stakingBoost
    );
  }

  /// @inheritdoc ISafetyPool
  function coverBadDebt(uint256 amount) external onlyRole(MANAGER_ROLE) {
    IERC20(asset()).transfer(msg.sender, amount);
    emit BadDebtCovered(amount, msg.sender);
  }

  function setStakingBoost(address _stakingBoost) external onlyRole(DEFAULT_ADMIN_ROLE) {
    staking = IOmnichainStaking(_stakingBoost);
  }

  /// @dev Override the _calculateBoostedBalance function to account for the withdrawal queue
  function _calculateBoostedBalance(
    address account
  ) internal view override returns (uint256 boostedBalance_, uint256 boostedTotalSupply_) {
    if (withdrawalTimestamp[account] > 0) return (0, _boostedTotalSupply);
    (boostedBalance_, boostedTotalSupply_) = super._calculateBoostedBalance(account);
  }
}
