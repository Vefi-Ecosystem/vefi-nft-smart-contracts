pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './interfaces/IDeployableCollection.sol';
import './interfaces/IMarketPlace.sol';
import './DeployableCollection.sol';

contract MarketPlace is IMarketPlace, Context, AccessControl, ReentrancyGuard {
  using Counters for Counters.Counter;

  Counters.Counter private _itemsSold;
  Counters.Counter private _bidsMade;
  Counters.Counter private _collectionsDeployed;

  bytes32 public MOD_ROLE = keccak256(abi.encode('MOD'));
  mapping(address => bool) public _collectionState;

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'ONLY_ADMIN');
    _;
  }

  modifier onlyMod() {
    require(hasRole(MOD_ROLE, _msgSender()), 'ONLY_MOD');
    _;
  }

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setRoleAdmin(MOD_ROLE, DEFAULT_ADMIN_ROLE);
  }

  function deployCollection(
    string memory name_,
    string memory symbol_,
    string memory category_,
    address paymentReceiver_,
    address[] memory acceptedCurrencies_
  ) external {
    bytes memory _byteCode = abi.encodePacked(
      type(DeployableCollection).creationCode,
      abi.encode(name_, symbol_, _msgSender(), category_, paymentReceiver_, acceptedCurrencies_)
    );
    bytes32 _salt = keccak256(abi.encode(name_, _msgSender()));
    address _collection;

    assembly {
      _collection := create2(0, add(_byteCode, 0x20), mload(_byteCode), _salt)
    }
    _collectionState[_collection] = true;
    emit CollectionDeployed(_collection, _msgSender(), block.timestamp);
  }
}
