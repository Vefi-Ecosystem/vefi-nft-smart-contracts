pragma solidity ^0.8.0;

interface IDeployableCollection {
  function _collectionOwner() external returns (address);
}
