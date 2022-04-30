pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './interfaces/IDeployableCollection.sol';

contract MarketPlace is Context, AccessControl, ReentrancyGuard {
  using Counters for Counters.Counter;

  Counters.Counter private _itemsSold;
  Counters.Counter private _bidsMade;
  Counters.Counter private _collectionsDeployed;
}
