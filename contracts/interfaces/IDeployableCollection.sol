pragma solidity ^0.8.0;

interface IDeployableCollection {
  function _collectionOwner() external returns (address);

  function _addMod(address _mod) external returns (bool);

  function _category() external returns (bytes32);
}
