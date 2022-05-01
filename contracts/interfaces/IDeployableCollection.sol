pragma solidity ^0.8.0;

interface IDeployableCollection {
  function _collectionOwner() external view returns (address);

  function _addMod(address _mod) external returns (bool);

  function _removeMod(address _mod) external returns (bool);

  function _category() external view returns (bytes32);

  function _paymentReceiver() external view returns (address payable);

  function _acceptedCurrency(address) external returns (bool);

  function mintFor(string memory _tokenURI, address to) external returns (uint256);
}
