// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IPoolConfigurator} from "../interfaces/IPoolConfigurator.sol";
import {ConfiguratorInputTypes} from "../protocol/libraries/types/ConfiguratorInputTypes.sol";

contract BatchPoolConfigurator {
    address public poolConfigurator;

    /**
     * @dev Constructor that sets the initial poolConfigurator address
     * @param _poolConfigurator Address of the initial poolConfigurator contract
     */
    constructor(address _poolConfigurator) {
        poolConfigurator = _poolConfigurator;
    }

    /**
     * @dev Internal function to perform delegatecall
     */
    function _delegate() private {
        (bool ok, ) = poolConfigurator.delegatecall(msg.data);
        require(ok, "delegatecall failed");
    }

    /**
     * @notice Fallback function to delegate calls to the poolConfigurator contract
     */
    fallback() external payable {
        _delegate();
    }

    /**
     * @notice Receive function to handle plain ether transfers
     */
    receive() external payable {
        _delegate();
    }

    /**
     * @notice Sets a new poolConfigurator address
     * @param _poolConfigurator Address of the new poolConfigurator contract
     */
    function setImplementation(address _poolConfigurator) external {
        poolConfigurator = _poolConfigurator;
    }

    /**
     * @notice Batch update AToken configurations
     * @param inputs Array of UpdateATokenInput structures
     */
    function batchUpdateAToken(ConfiguratorInputTypes.UpdateATokenInput[] calldata inputs) external {
        for (uint256 i = 0; i < inputs.length; i++) {
            _delegateUpdateAToken(inputs[i]);
        }
    }

    /**
     * @dev Internal function to delegate the updateAToken call
     * @param input UpdateATokenInput structure
     */
    function _delegateUpdateAToken(ConfiguratorInputTypes.UpdateATokenInput calldata input) internal {
        // Encode the call data for updateAToken function
        bytes memory data = abi.encodeWithSelector(
            IPoolConfigurator.updateAToken.selector,
            input
        );

        // Perform the delegatecall
        (bool success, bytes memory returnData) = poolConfigurator.delegatecall(data);

        require(success, string(abi.encodePacked("Delegate call failed: ", returnData)));
    }
}
