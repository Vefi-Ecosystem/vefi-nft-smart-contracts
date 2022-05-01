pragma solidity ^0.8.0;

interface IMarketPlace {
  function _collectionState(address collection) external view returns (bool);

  function _collectionAllowed(address collection) external view returns (bool);

  function _utilityToken() external view returns (address);

  function _requiredHold() external view returns (uint256);

  function _mintFeeInEther() external view returns (uint256);

  function _percentageDiscount() external view returns (int256);

  function _percentageForCollectionOwners() external view returns (int256);

  enum MarketItemStatus {
    ON_GOING,
    FINALIZED,
    CANCELLED
  }

  event CollectionDeployed(
    address _collection,
    address indexed _owner,
    uint256 timestamp,
    string _name,
    string _category,
    string _symbol
  );
  event MarketItemCreated(
    address indexed _creator,
    address indexed _collection,
    uint256 _tokenId,
    address _currency,
    uint256 _startingPriceInEther
  );
  event MarketItemEnded(
    address indexed _creator,
    address indexed _collection,
    uint256 _tokenId,
    address _currency,
    uint256 _finalPriceInEther
  );
  event BidCreated(
    address indexed _createdBy,
    uint256 indexed _tokenId,
    address indexed _collection,
    uint256 timestamp,
    uint256 _totalBidsMade,
    uint256 _price
  );
  event BidUpdated(address indexed _createdBy, uint256 indexed _tokenId, uint256 _newPrice, uint256 timestamp);
  event SaleMade(
    address indexed _seller,
    address indexed _buyer,
    uint256 indexed _tokenId,
    address _collection,
    address _paymentToken,
    uint256 _amount
  );

  struct MarketItem {
    address _creator;
    address payable _paymentReceiver;
    uint256 _tokenId;
    address _currency;
    uint256 _price;
    MarketItemStatus _status;
  }

  struct BidItem {
    address _createdBy;
    address _receiver;
    uint256 _bidAmount;
    uint256 _tokenId;
  }
}
