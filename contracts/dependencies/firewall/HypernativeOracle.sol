// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IHypernativeOracle} from './interfaces/IHypernativeOracle.sol';
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';

contract HypernativeOracle is IHypernativeOracle, AccessControl {
  struct OracleRecord {
    uint256 registrationTime;
    bool isUnsafe;
    bool isBlacklisted;
  }

  bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');
  bytes32 public constant CONSUMER_ROLE = keccak256('CONSUMER_ROLE');
  uint256 internal threshold = 2 minutes;

  mapping(bytes32 => OracleRecord) internal accountHashToRecord;

  event ConsumerAdded(address consumer);
  event ConsumerRemoved(address consumer);
  event Registered(address consumer, address account, bool isStrictMode);
  event Whitelisted(bytes32[] hashedAccounts);
  event Allowed(bytes32[] hashedAccounts);
  event Blacklisted(bytes32[] hashedAccounts);
  event Unblacklisted(bytes32[] hashedAccounts);
  event TimeThresholdChanged(uint256 threshold);

  error InteractionNotAllowedUnsafe();
  error InteractionNotAllowedBlacklisted();
  error InteractionNotAllowedTimeThreshold();

  error AccountAlreadyRegistered();
  error HypernativeOracleCallerNotAdmin();
  error HypernativeOracleCallerNotOperator();
  error HypernativeOracleCallerNotConsumer();

  modifier onlyAdmin() {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
      revert HypernativeOracleCallerNotAdmin();
    }
    _;
  }

  modifier onlyOperator() {
    if (!hasRole(OPERATOR_ROLE, msg.sender)) {
      revert HypernativeOracleCallerNotOperator();
    }
    _;
  }

  modifier onlyConsumer() {
    if (!hasRole(CONSUMER_ROLE, msg.sender)) {
      revert HypernativeOracleCallerNotConsumer();
    }
    _;
  }

  constructor(address _admin) {
    _grantRole(DEFAULT_ADMIN_ROLE, _admin);
  }

  /**
   * @dev Consumer only function, can be used to register an account in order to allow it to interact with the protocol
   * @param _account address of the account
   * @param isStrictMode boolean to set the account in strict mode, passed from the consumer state
   */
  function register(address _account, bool isStrictMode) external onlyConsumer {
    bytes32 _hashedAccount = keccak256(abi.encodePacked(_account, address(this)));
    if (accountHashToRecord[_hashedAccount].registrationTime != 0) {
      revert AccountAlreadyRegistered();
    }
    if (isStrictMode) {
      accountHashToRecord[_hashedAccount].isUnsafe = true;
    }
    accountHashToRecord[_hashedAccount].registrationTime = block.timestamp;
    emit Registered(msg.sender, _account, isStrictMode);
  }

  /**
   * @dev Operator only function, can be used to whitelist accounts in order to allow them to interact with the protocol without restrictions
   * @param hashedAccounts array of hashed accounts
   */
  function whitelist(bytes32[] calldata hashedAccounts) public onlyOperator {
    for (uint256 i; i < hashedAccounts.length; ++i) {
      accountHashToRecord[hashedAccounts[i]].registrationTime = block.timestamp - threshold - 1;
      accountHashToRecord[hashedAccounts[i]].isUnsafe = false;
    }
    emit Whitelisted(hashedAccounts);
  }

  /**
   * @dev Operator only function, can be used to blacklist accounts in order to prevent them from interacting with the protocol
   * @param hashedAccounts array of hashed accounts
   */
  function blacklist(bytes32[] calldata hashedAccounts) public onlyOperator {
    for (uint256 i; i < hashedAccounts.length; ++i) {
      accountHashToRecord[hashedAccounts[i]].isBlacklisted = true;
    }
    emit Blacklisted(hashedAccounts);
  }

  function unblacklist(bytes32[] calldata hashedAccounts) public onlyOperator {
    for (uint256 i; i < hashedAccounts.length; ++i) {
      accountHashToRecord[hashedAccounts[i]].isBlacklisted = false;
    }
    emit Unblacklisted(hashedAccounts);
  }

  /**
   * @dev Admin only function, can be used to block any interaction with the protocol, meassured in seconds
   */
  function changeTimeThreshold(uint256 _newThreshold) public onlyAdmin {
    require(_newThreshold >= 2 minutes, 'Threshold must be greater than 2 minutes');
    threshold = _newThreshold;
    emit TimeThresholdChanged(threshold);
  }

  function addConsumers(address[] memory consumers) public onlyAdmin {
    for (uint256 i; i < consumers.length; ++i) {
      _grantRole(CONSUMER_ROLE, consumers[i]);
      emit ConsumerAdded(consumers[i]);
    }
  }

  function revokeConsumers(address[] memory consumers) public onlyAdmin {
    for (uint256 i; i < consumers.length; ++i) {
      _revokeRole(CONSUMER_ROLE, consumers[i]);
      emit ConsumerRemoved(consumers[i]);
    }
  }

  function addOperator(address operator) public onlyAdmin {
    _grantRole(OPERATOR_ROLE, operator);
  }

  function revokeOperator(address operator) public onlyAdmin {
    _revokeRole(OPERATOR_ROLE, operator);
  }

  function changeAdmin(address _newAdmin) public onlyAdmin {
    require(_newAdmin != address(0), 'Oracle admin cannot be set to 0');
    _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
  }

  /**
   * @dev Consumer only function, can be used to validate if an account is allowed to interact with the protocol
   * @param _origin address of the origin account
   * @param _sender address of the sender account
   */
  function validateForbiddenContextInteraction(
    address _origin,
    address _sender
  ) external view onlyConsumer {
    bytes32 hashedOrigin = keccak256(abi.encodePacked(_origin, address(this)));
    bytes32 hashedSender = keccak256(abi.encodePacked(_sender, address(this)));
    if (isBlacklisted(hashedOrigin) || isBlacklisted(hashedSender)) {
      revert InteractionNotAllowedBlacklisted();
    }
    if (accountHashToRecord[hashedSender].registrationTime == 0) {
      revert AccountAlreadyRegistered();
    }
    if (isUnsafe(hashedOrigin) || isUnsafe(hashedSender)) {
      revert InteractionNotAllowedUnsafe();
    } else if (!isTimeExceeded(hashedSender)) {
      revert InteractionNotAllowedTimeThreshold();
    }
  }

  /**
   * @dev Consumer only function, can be used to validate if an account is allowed to interact with the protocol
   * @param _account address of the account
   */
  function validateForbiddenAccountInteraction(address _account) external view onlyConsumer {
    bytes32 hashedAccount = keccak256(abi.encodePacked(_account, address(this)));
    if (isBlacklisted(hashedAccount)) {
      revert InteractionNotAllowedBlacklisted();
    }
    if (accountHashToRecord[hashedAccount].registrationTime == 0) {
      revert AccountAlreadyRegistered();
    }
    if (isUnsafe(hashedAccount)) {
      revert InteractionNotAllowedUnsafe();
    } else if (!isTimeExceeded(hashedAccount)) {
      revert InteractionNotAllowedTimeThreshold();
    }
  }

  /**
   * @dev Consumer only function, can be used to validate if an account is blacklisted from interacting with the protocol
   * @param _account address of the account
   */
  function validateBlacklistedAccountInteraction(address _account) external view onlyConsumer {
    bytes32 hashedAccount = keccak256(abi.encodePacked(_account, address(this)));
    if (isBlacklisted(hashedAccount)) {
      revert InteractionNotAllowedBlacklisted();
    }
  }

  function isTimeExceeded(bytes32 _hashedAccount) private view returns (bool) {
    return block.timestamp - accountHashToRecord[_hashedAccount].registrationTime > threshold;
  }

  function isUnsafe(bytes32 _hashedAccount) private view returns (bool) {
    return accountHashToRecord[_hashedAccount].isUnsafe;
  }

  function isBlacklisted(bytes32 _hashedAccount) private view returns (bool) {
    return accountHashToRecord[_hashedAccount].isBlacklisted;
  }
}
