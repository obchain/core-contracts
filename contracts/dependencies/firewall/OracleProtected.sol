// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IHypernativeOracle} from './interfaces/IHypernativeOracle.sol';
import {VersionedInitializable} from '../../protocol/libraries/aave-upgradeability/VersionedInitializable.sol';

error OracleProtectedCallerNotEOA();
error OracleProtectedCallerNotAdmin();
error OracleProtectedZeroAddress();

abstract contract OracleProtected is VersionedInitializable {
  bytes32 private constant HYPERNATIVE_ORACLE_STORAGE_SLOT =
    bytes32(uint256(keccak256('eip1967.hypernative.oracle')) - 1);
  bytes32 private constant HYPERNATIVE_ADMIN_STORAGE_SLOT =
    bytes32(uint256(keccak256('eip1967.hypernative.admin')) - 1);
  bytes32 private constant HYPERNATIVE_MODE_STORAGE_SLOT =
    bytes32(uint256(keccak256('eip1967.hypernative.is_strict_mode')) - 1);

  event OracleAdminChanged(address indexed previousAdmin, address indexed newAdmin);
  event OracleAddressChanged(address indexed previousOracle, address indexed newOracle);

  modifier onlyOracleApproved() {
    address oracleAddress = _hypernativeOracle();
    if (oracleAddress == address(0)) {
      _;
      return;
    }

    IHypernativeOracle oracle = IHypernativeOracle(oracleAddress);
    oracle.validateForbiddenContextInteraction(tx.origin, msg.sender);
    _;
  }

  modifier onlyOracleApprovedAllowEOA() {
    address oracleAddress = _hypernativeOracle();
    if (oracleAddress == address(0)) {
      _;
      return;
    }
    IHypernativeOracle oracle = IHypernativeOracle(oracleAddress);
    oracle.validateBlacklistedAccountInteraction(msg.sender);
    if (tx.origin == msg.sender) {
      _;
      return;
    }

    oracle.validateForbiddenContextInteraction(tx.origin, msg.sender);
    _;
  }

  modifier onlyNotBlacklistedEOA() {
    address oracleAddress = _hypernativeOracle();
    if (oracleAddress == address(0)) {
      _;
      return;
    }

    IHypernativeOracle oracle = IHypernativeOracle(oracleAddress);
    if (msg.sender != tx.origin) {
      revert OracleProtectedCallerNotEOA();
    }
    oracle.validateBlacklistedAccountInteraction(msg.sender);
    _;
  }

  modifier onlyOracleAdmin() {
    if (msg.sender != hypernativeOracleAdmin()) {
      revert OracleProtectedCallerNotAdmin();
    }
    _;
  }

  function __OracleProtected_init(address _oracle, address _admin) internal initializer {
    _changeOracleAdmin(_admin);
    if (_oracle == address(0)) {
      revert OracleProtectedZeroAddress();
    }
    setOracle(_oracle);
  }

  function oracleRegister(address _account) public virtual {
    address oracleAddress = _hypernativeOracle();
    bool isStrictMode = _hypernativeOracleIsStrictMode();
    IHypernativeOracle oracle = IHypernativeOracle(oracleAddress);
    oracle.register(_account, isStrictMode);
  }

  /**
   * @dev Admin only function, sets new oracle admin. set to address(0) to revoke oracle
   */
  function setOracle(address _oracle) public onlyOracleAdmin {
    address oldOracle = _hypernativeOracle();
    _setAddressBySlot(HYPERNATIVE_ORACLE_STORAGE_SLOT, _oracle);
    emit OracleAddressChanged(oldOracle, _oracle);
  }

  function setIsStrictMode(bool _mode) public onlyOracleAdmin {
    _setValueBySlot(HYPERNATIVE_MODE_STORAGE_SLOT, _mode ? 1 : 0);
  }

  function changeOracleAdmin(address _newAdmin) public onlyOracleAdmin {
    if (_newAdmin == address(0)) {
      revert OracleProtectedZeroAddress();
    }
    _changeOracleAdmin(_newAdmin);
  }

  function _changeOracleAdmin(address _newAdmin) internal {
    address oldAdmin = hypernativeOracleAdmin();
    _setAddressBySlot(HYPERNATIVE_ADMIN_STORAGE_SLOT, _newAdmin);
    emit OracleAdminChanged(oldAdmin, _newAdmin);
  }

  function _setAddressBySlot(bytes32 slot, address newAddress) internal {
    assembly {
      sstore(slot, newAddress)
    }
  }

  function _setValueBySlot(bytes32 _slot, uint256 _value) internal {
    assembly {
      sstore(_slot, _value)
    }
  }

  function hypernativeOracleAdmin() public view returns (address) {
    return _getAddressBySlot(HYPERNATIVE_ADMIN_STORAGE_SLOT);
  }

  function _hypernativeOracleIsStrictMode() private view returns (bool) {
    return _getValueBySlot(HYPERNATIVE_MODE_STORAGE_SLOT) == 1;
  }

  function _hypernativeOracle() private view returns (address) {
    return _getAddressBySlot(HYPERNATIVE_ORACLE_STORAGE_SLOT);
  }

  function _getAddressBySlot(bytes32 slot) internal view returns (address addr) {
    assembly {
      addr := sload(slot)
    }
  }

  function _getValueBySlot(bytes32 _slot) internal view returns (uint256 value) {
    assembly {
      value := sload(_slot)
    }
  }
}
