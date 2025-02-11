// SPDX-License-Identifier: PRIVATE
// all rights reserved to Hexagate

pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

interface IGator {
    function initialize(address owner) external;

    function enter(bytes4 signature) external;
    function exit(bytes4 signature) external;

    function approveClient(address client) external;
    function approveClients(address[] calldata clients) external;

    function denyClient(address client) external;
    function denyClients(address[] calldata clients) external;

    function approveFlow(bytes32 flow) external;
    function approveFlows(bytes32[] calldata flows) external;

    function denyFlow(bytes32 flow) external;
    function denyFlows(bytes32[] calldata flows) external;

    function enable() external;
    function disable() external;
}

error ClientNotApproved(address client);
error FlowNotApproved(bytes32 flow);
error AlreadyEnabled();
error AlreadyDisabled();

contract Gator is Ownable, Initializable, UUPSUpgradeable {
    // == Events ==
    event Enabled();
    event Disabled();
    event ClientApproved(address indexed client);
    event ClientDenied(address indexed client);
    event FlowApproved(bytes32 indexed flow);
    event FlowDenied(bytes32 indexed flow);

    // == Constants ==
    uint256 private constant FALSE = 1;
    uint256 private constant TRUE = 2;

    // == Storage data ==
    uint256 public $enabled;

    bytes32 private $flow;
    mapping(bytes32 => uint256) private $allowedFlows;
    mapping(address => uint256) private $gatedClients;

    bytes32 private $txIdentifier;

    address[] $depthStack;


    // This contract is to be used behind a proxy, so the constructor should not be used
    constructor() {
        _disableInitializers();
    }

    // Allow upgrades to this contract by the owner
    function _authorizeUpgrade(address) internal override onlyOwner {}

    // This initializer is used instead of the constructor
    function initialize(address owner) external initializer {
        _transferOwnership(owner);
        $enabled = TRUE;
    }

    // == Modifiers ==

    modifier onlyGated() {
        if ($gatedClients[msg.sender] != TRUE) {
            revert ClientNotApproved(msg.sender);
        }

        _;
    }

    // == Gator client called functions ==

    function _checkFlow(bytes4 selector, bool isEnter) internal {
        if ($enabled == FALSE) {
            return;
        }

        // Calculate the the new flow identifier according to the current state
        bytes32 flow = keccak256(abi.encodePacked($flow, msg.sender, selector, isEnter));
        if ($allowedFlows[flow] != TRUE) {
            revert FlowNotApproved(flow);
        }

        $flow = flow;
    }

    function _clearFlow() internal {
        $flow = bytes32(0);
    }

    function _txIdentifier() internal view returns (bytes32) {
        uint256 id = uint256(uint160(tx.origin));
        id |= (block.number << 160);
        return bytes32(id);
    }

    function enter(bytes4 selector) external onlyGated {
        // Clear on new tx
        bytes32 txId = _txIdentifier();
        if ($txIdentifier != txId) {
            $txIdentifier = txId;
            _clearFlow();
        }

        $depthStack.push(msg.sender);

        if ($depthStack.length >= 2) {
            address prev = $depthStack[$depthStack.length - 2];
            if (prev == msg.sender) {
                // Internal call - no need to check flow
                return;
            }
        }

        _checkFlow(selector, true);
    }

    function exit(bytes4 selector) external onlyGated {
        address last = $depthStack[$depthStack.length - 1];
        $depthStack.pop();

        if ($depthStack.length > 0) {
            address prev = $depthStack[$depthStack.length - 1];
            if (prev == last) {
                // Internal call - no need to check flow
                return;
            }
        }

        _checkFlow(selector, false);
    }

    // == Admin functions ==

    function approveFlow(bytes32 flow) public onlyOwner {
        $allowedFlows[flow] = TRUE;
        emit FlowApproved(flow);
    }

    function approveFlows(bytes32[] calldata flows) external onlyOwner {
        for (uint256 i = 0; i < flows.length; i++) {
            approveFlow(flows[i]);
        }
    }

    function denyFlow(bytes32 flow) public onlyOwner {
        $allowedFlows[flow] = FALSE;
        emit FlowDenied(flow);
    }

    function denyFlows(bytes32[] calldata flows) external onlyOwner {
        for (uint256 i = 0; i < flows.length; i++) {
            denyFlow(flows[i]);
        }
    }

    function approveClient(address client) public onlyOwner {
        $gatedClients[client] = TRUE;
        emit ClientApproved(client);
    }

    function approveClients(address[] calldata clients) external onlyOwner {
        for (uint256 i = 0; i < clients.length; i++) {
            approveClient(clients[i]);
        }
    }

    function denyClient(address client) public onlyOwner {
        $gatedClients[client] = FALSE;
        emit ClientDenied(client);
    }

    function denyClients(address[] calldata clients) external onlyOwner {
        for (uint256 i = 0; i < clients.length; i++) {
            denyClient(clients[i]);
        }
    }

    function enable() public onlyOwner {
        if ($enabled == TRUE) {
            revert AlreadyEnabled();
        }
        $enabled = TRUE;
        emit Enabled();
    }

    function disable() public onlyOwner {
        if ($enabled == FALSE) {
            revert AlreadyDisabled();
        }
        $enabled = FALSE;
        emit Disabled();
    }
}
