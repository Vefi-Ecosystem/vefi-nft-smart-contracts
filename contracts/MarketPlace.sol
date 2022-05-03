pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './interfaces/IDeployableCollection.sol';
import './interfaces/IMarketPlace.sol';
import './DeployableCollection.sol';

contract MarketPlace is IMarketPlace, IERC721Receiver, Context, AccessControl, ReentrancyGuard {
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  Counters.Counter private _itemsSold;
  Counters.Counter private _collectionsDeployed;
  Counters.Counter private _totalNfts;
  Counters.Counter private _offersMade;

  bytes32 public MOD_ROLE = keccak256(abi.encode('MOD'));
  mapping(address => bool) public _collectionState;
  mapping(address => bool) public _collectionAllowed;
  address payable public _feeReceiver;
  address public _utilityToken;
  uint256 public _requiredHold;
  uint256 public _mintFeeInEther;
  uint256 public _collectionDeployFeeInEther;
  int256 public _percentageDiscount;
  int256 public _percentageForCollectionOwners;
  mapping(bytes32 => MarketItem) public _auctions;
  mapping(bytes32 => OfferItem) public _offers;
  bytes32[] private allOffers;
  address[] public _collections;

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
    int256 percentageForCollectionOwners_,
    uint256 collectionDeployFeeInEther_,
    address feeReceiver_
  ) {
    require(IERC20(utilityToken_).totalSupply() > requiredHold_);
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MOD_ROLE, _msgSender());
    _setRoleAdmin(MOD_ROLE, DEFAULT_ADMIN_ROLE);
    _utilityToken = utilityToken_;
    _requiredHold = requiredHold_;
    _mintFeeInEther = mintFeeInEther_;
    _percentageDiscount = percentageDiscount_;
    _percentageForCollectionOwners = percentageForCollectionOwners_;
    _collectionDeployFeeInEther = collectionDeployFeeInEther_;
    _feeReceiver = payable(feeReceiver_);
  }

  function deployCollection(
    string memory name_,
    string memory symbol_,
    string memory category_,
    address paymentReceiver_,
    string memory _imageURI
  ) external payable nonReentrant {
    uint256 _fee = IERC20(_utilityToken).balanceOf(_msgSender()) >= _requiredHold
      ? _collectionDeployFeeInEther.sub((uint256(_percentageDiscount).mul(_collectionDeployFeeInEther)).div(100))
      : _collectionDeployFeeInEther;
    require(msg.value >= _fee, 'FEE_TOO_LOW');
    bytes memory _byteCode = abi.encodePacked(
      type(DeployableCollection).creationCode,
      abi.encode(name_, symbol_, _msgSender(), category_, paymentReceiver_, _imageURI)
    );
    bytes32 _salt = keccak256(abi.encode(name_, _msgSender()));
    address _collection;

    assembly {
      _collection := create2(0, add(_byteCode, 32), mload(_byteCode), _salt)
    }
    _collectionState[_collection] = true;
    _collectionAllowed[_collection] = true;
    _collections.push(_collection);
    _collectionsDeployed.increment();
    emit CollectionDeployed(_collection, _msgSender(), block.timestamp, name_, category_, symbol_);
  }

  function mintNFT(
    address collection,
    string memory tokenURI_,
    address _for
  ) external payable nonReentrant onlyActiveCollection(collection) onlyAllowedCollection(collection) returns (bool) {
    uint256 _fee = IERC20(_utilityToken).balanceOf(_msgSender()) >= _requiredHold
      ? _mintFeeInEther.sub((uint256(_percentageDiscount).mul(_mintFeeInEther)).div(100))
      : _mintFeeInEther;

    require(msg.value >= _fee);

    address _paymentReceiver = IDeployableCollection(collection)._paymentReceiver();
    uint256 _feeForOwner = (uint256(_percentageForCollectionOwners).mul(_fee)).div(100);

    _safeMintFor(collection, tokenURI_, _for);
    _safeTransferETH(_paymentReceiver, _feeForOwner);

    uint256 _tokenId = IDeployableCollection(collection).lastMintedForIDs(_msgSender());
    _totalNfts.increment();
    emit Mint(collection, _tokenId, block.timestamp, tokenURI_, _msgSender());
    return true;
  }

  function destroyNFT(address collection, uint256 tokenId)
    external
    nonReentrant
    onlyActiveCollection(collection)
    onlyAllowedCollection(collection)
    onlyMod
  {
    IDeployableCollection(collection).burn(tokenId);
    _totalNfts.decrement();
    emit Burn(collection, tokenId, block.timestamp);
  }

  function disallowCollection(address collection) external onlyMod onlyActiveCollection(collection) {
    _collectionAllowed[collection] = false;
  }

  function deactivateCollection(address collection) external onlyMod onlyAllowedCollection(collection) {
    _collectionState[collection] = false;
  }

  function activateCollection(address collection) external onlyAllowedCollection(collection) onlyMod {
    _collectionState[collection] = true;
  }

  function allowCollection(address collection) external onlyActiveCollection(collection) onlyMod {
    _collectionAllowed[collection] = true;
  }

  function placeForSale(
    uint256 _tokenId,
    address collection,
    address _paymentReceiver,
    address _currency,
    uint256 _price
  ) external nonReentrant onlyActiveCollection(collection) onlyAllowedCollection(collection) returns (bool) {
    require(IERC721(collection).ownerOf(_tokenId) == _msgSender());
    require(IERC721(collection).getApproved(_tokenId) == address(this));

    IERC721(collection).safeTransferFrom(_msgSender(), address(this), _tokenId);
    bytes32 marketItemId = keccak256(abi.encode(_msgSender(), collection, _tokenId));
    _auctions[marketItemId] = MarketItem({
      _creator: _msgSender(),
      _paymentReceiver: payable(_paymentReceiver),
      _tokenId: _tokenId,
      _currency: _currency,
      _price: _price,
      _status: MarketItemStatus.ON_GOING,
      _collection: collection
    });
    emit MarketItemCreated(_msgSender(), collection, _tokenId, _currency, _price, marketItemId, block.timestamp);
    return true;
  }

  function cancelSale(bytes32 marketId) external {
    MarketItem storage _marketItem = _auctions[marketId];
    require(_marketItem._creator == _msgSender(), 'NOT_MARKET_ITEM_CREATOR');
    _marketItem._creator = address(0);
    _marketItem._paymentReceiver = payable(address(0));
    _marketItem._status = MarketItemStatus.CANCELLED;

    emit MarketItemCancelled(marketId, block.timestamp);
  }

  function buyItem(bytes32 _marketId, uint256 _buyAmount) external payable nonReentrant {
    MarketItem storage _marketItem = _auctions[_marketId];
    require(_marketItem._status == MarketItemStatus.ON_GOING, 'MARKET_ITEM_CLOSED');

    if (_marketItem._currency == address(0)) {
      require(msg.value == _marketItem._price);
      require(_buyAmount == uint256(0) || _buyAmount == msg.value, 'BID_AMOUNT_MUST_BE_ZERO_OR_EQUAL_TO_VALUE');
      _safeTransferETH(_marketItem._paymentReceiver, msg.value);
    } else {
      require(_buyAmount == _marketItem._price, 'BUY_AMOUNT_NOT_SAME_AS_PRICE');
      require(IERC20(_marketItem._currency).balanceOf(_msgSender()) >= _buyAmount, 'NOT_ENOUGH_BALANCE');
      require(IERC20(_marketItem._currency).allowance(_msgSender(), address(this)) >= _buyAmount, 'NO_ALLOWANCE');
      _safeTransferFrom(_marketItem._currency, _msgSender(), _marketItem._paymentReceiver, _buyAmount);
    }
    IERC721(_marketItem._collection).safeTransferFrom(address(this), _msgSender(), _marketItem._tokenId);
    _marketItem._status = MarketItemStatus.FINALIZED;
    _itemsSold.increment();
    emit MarketItemEnded(_marketId, block.timestamp);
    emit SaleMade(
      _marketItem._creator,
      _msgSender(),
      _marketItem._tokenId,
      _marketItem._collection,
      _marketItem._currency,
      _buyAmount
    );
  }

  function placeOffer(
    address collection,
    uint256 _tokenId,
    address _recipient,
    address _token,
    uint256 _bidAmount
  ) external onlyAllowedCollection(collection) onlyActiveCollection(collection) returns (bytes32 offerId) {
    require(IERC20(_token).allowance(_msgSender(), address(this)) >= _bidAmount, 'NO_ALLOWANCE');
    offerId = keccak256(abi.encode(collection, _tokenId, _msgSender()));
    _offers[offerId] = OfferItem({
      _creator: _msgSender(),
      _recipient: _recipient,
      _collection: collection,
      _tokenId: _tokenId,
      _token: _token,
      _bidAmount: _bidAmount,
      _status: OrderItemStatus.STARTED
    });
    _offersMade.increment();
    allOffers.push(offerId);
    emit OrderMade(_msgSender(), _recipient, collection, _tokenId, _token, _bidAmount);
  }

  function acceptOffer(bytes32 _offerId) external {
    OfferItem storage _offerItem = _offers[_offerId];
    require(_offerItem._status == OrderItemStatus.STARTED);
    require(IERC721(_offerItem._collection).ownerOf(_offerItem._tokenId) == _msgSender());
    require(IERC721(_offerItem._collection).getApproved(_offerItem._tokenId) == address(this));

    _safeTransferFrom(_offerItem._token, _offerItem._creator, _msgSender(), _offerItem._bidAmount);

    IERC721(_offerItem._collection).safeTransferFrom(_msgSender(), _offerItem._recipient, _offerItem._tokenId);

    _offerItem._status = OrderItemStatus.ACCEPTED;

    for (uint256 i = 0; i < allOffers.length; i++) {
      OfferItem storage _innerOfferItem = _offers[allOffers[i]];

      if (_innerOfferItem._tokenId == _offerItem._tokenId) {
        _innerOfferItem._status = OrderItemStatus.CANCELLED;
        emit OrderItemCancelled(allOffers[i], block.timestamp);
      }
    }

    emit OrderItemEnded(_offerId, block.timestamp);
  }

  function rejectOffer(bytes32 _offerId) external {
    OfferItem storage _offerItem = _offers[_offerId];
    require(_offerItem._status == OrderItemStatus.STARTED, 'OFFER_ALREADY_FINALIZED');
    require(IERC721(_offerItem._collection).ownerOf(_offerItem._tokenId) == _msgSender());
    _offerItem._status = OrderItemStatus.REJECTED;
    emit OrderItemRejected(_offerId, block.timestamp);
  }

  function cancelOffer(bytes32 _offerId) external {
    OfferItem storage _offerItem = _offers[_offerId];
    require(_offerItem._status == OrderItemStatus.STARTED);
    require(_offerItem._creator == _msgSender());
    _offerItem._status = OrderItemStatus.CANCELLED;
    emit OrderItemCancelled(_offerId, block.timestamp);
  }

  function _addMod(address _mod) external {
    grantRole(MOD_ROLE, _mod);
  }

  function _removeMod(address _mod) external {
    revokeRole(MOD_ROLE, _mod);
  }

  function _safeTransferETH(address to, uint256 _value) private returns (bool) {
    (bool success, ) = to.call{value: _value}(new bytes(0));
    require(success, 'COULD_NOT_TRANSFER_ETHER');
    return true;
  }

  function _safeTransfer(
    address token,
    address to,
    uint256 value
  ) private returns (bool) {
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(bytes4(keccak256(bytes('transfer(address,uint256)'))), to, value)
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'COULD_NOT_TRANSFER_TOKEN');
    return true;
  }

  function _safeTransferFrom(
    address token,
    address owner,
    address recipient,
    uint256 value
  ) private returns (bool) {
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(bytes4(keccak256(bytes('transferFrom(address,address,uint256)'))), owner, recipient, value)
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'COULD_NOT_TRANSFER_TOKEN');
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

  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function takeAccumulatedETH() external onlyAdmin returns (bool) {
    _safeTransferETH(_feeReceiver, address(this).balance);
    return true;
  }

  function takeAccumulatedToken(address token) external onlyAdmin returns (bool) {
    _safeTransfer(token, _feeReceiver, IERC20(token).balanceOf(address(this)));
    return true;
  }

  function totalItemsSold() public view returns (uint256) {
    return _itemsSold.current();
  }

  function totalDeployedCollections() public view returns (uint256) {
    return _collectionsDeployed.current();
  }

  function totalNFTs() public view returns (uint256) {
    return _totalNfts.current();
  }

  function totalOffersMade() public view returns (uint256) {
    return _offersMade.current();
  }

  function setPercentageDiscount(int256 percentageDiscount_) external onlyAdmin {
    _percentageDiscount = percentageDiscount_;
  }

  function setRequiredHold(uint256 requiredHold_) external onlyAdmin {
    _requiredHold = requiredHold_;
  }

  receive() external payable {}
}
