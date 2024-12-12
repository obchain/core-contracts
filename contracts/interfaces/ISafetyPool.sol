// SPDX-License-Identifier: BUSL-1.1
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

/**
 * @title Safety Pool
 * @author zerolend.xyz
 * @notice This is the main contract responsible for paying for bad debt.
 */
interface ISafetyPool {
  event BadDebtCovered(uint256 indexed amount, address indexed caller);

  function coverBadDebt(uint256 amount) external;

  function MANAGER_ROLE() external view returns (bytes32);
}
