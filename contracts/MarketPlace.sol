pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './interfaces/IDeployableCollection.sol';
import './interfaces/IMarketPlace.sol';
import './DeployableCollection.sol';

contract MarketPlace is IMarketPlace, Context, AccessControl, ReentrancyGuard {
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  Counters.Counter private _itemsSold;
  Counters.Counter private _bidsMade;
  Counters.Counter private _collectionsDeployed;

  bytes32 public MOD_ROLE = keccak256(abi.encode('MOD'));
  mapping(address => bool) public _collectionState;
  mapping(address => bool) public _collectionAllowed;
  address public _utilityToken;
  uint256 public _requiredHold;
  uint256 public _mintFeeInEther;
  int256 public _percentageDiscount;
  int256 public _percentageForCollectionOwners;

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'ONLY_ADMIN');
    _;
  }

  modifier onlyMod() {
    require(hasRole(MOD_ROLE, _msgSender()), 'ONLY_MOD');
    _;
  }

  modifier onlyActiveCollection(address collection) {
    require(_collectionState[collection], 'COLLECTION_NOT_ACTIVE');
    _;
  }

  modifier onlyAllowedCollection(address collection) {
    require(_collectionAllowed[collection], 'COLLECTION_NOT_ALLOWED');
    _;
  }

  constructor(
    address utilityToken_,
    uint256 requiredHold_,
    uint256 mintFeeInEther_,
    int256 percentageDiscount_,
    int256 percentageForCollectionOwners_
  ) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setRoleAdmin(MOD_ROLE, DEFAULT_ADMIN_ROLE);
    _utilityToken = utilityToken_;
    _requiredHold = requiredHold_;
    _mintFeeInEther = mintFeeInEther_;
    _percentageDiscount = percentageDiscount_;
    _percentageForCollectionOwners = percentageForCollectionOwners_;
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
      _collection := create2(0, add(_byteCode, 32), mload(_byteCode), _salt)
    }
    _collectionState[_collection] = true;
    _collectionAllowed[_collection] = true;
    emit CollectionDeployed(_collection, _msgSender(), block.timestamp, name_, category_, symbol_);
  }

  function mintNFT(address collection, string memory tokenURI_)
    external
    payable
    nonReentrant
    onlyActiveCollection(collection)
    onlyAllowedCollection(collection)
    returns (bool)
  {
    uint256 _fee = IERC20(_utilityToken).balanceOf(_msgSender()) >= _requiredHold
      ? _mintFeeInEther.sub((uint256(_percentageDiscount).mul(_mintFeeInEther)).div(100))
      : _mintFeeInEther;

    require(msg.value >= _fee, 'FEE_TOO_LOW');

    address _owner = IDeployableCollection(collection)._collectionOwner();
    uint256 _feeForOwner = (uint256(_percentageForCollectionOwners).mul(_fee)).div(100);
    require(_safeMintFor(collection, tokenURI_, _msgSender()), 'COULD_NOT_MINT');
    require(_safeTransferETH(_owner, _feeForOwner), 'COULD_NOT_TRANSFER_ETHER');
    return true;
  }

  function _safeTransferETH(address to, uint256 _value) private returns (bool) {
    (bool success, ) = to.call{value: _value}(new bytes(0));
    require(success, 'COULD_NOT_TRANSFER_ETHER');
    return true;
  }

  function _safeMintFor(
    address collection,
    string memory _tokenURI,
    address to
  ) private returns (bool) {
    (bool success, bytes memory data) = collection.call(
      abi.encodeWithSelector(bytes4(keccak256(bytes('mintFor(string,address)'))), _tokenURI, to)
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'COULD_NOT_MINT');
    return true;
  }
}
