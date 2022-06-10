pragma solidity ^0.8.0;

interface IDeployableCollection {
  function _collectionOwner() external view returns (address);

  function _collectionURI() external view returns (string memory);

  function _category() external view returns (bytes32);

  function _paymentReceiver() external view returns (address payable);

  function mintFor(string memory _tokenURI, address to) external returns (uint256);

  function burn(uint256 _tokenId) external;

  function lastMintedForIDs(address to) external view returns (uint256);
}
