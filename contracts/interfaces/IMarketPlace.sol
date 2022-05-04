pragma solidity ^0.8.0;

interface IMarketPlace {
  function _collections(uint256) external view returns (address);

  enum MarketItemStatus {
    ON_GOING,
    FINALIZED,
    CANCELLED
  }

  enum OrderItemStatus {
    STARTED,
    ACCEPTED,
    REJECTED,
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
  event Mint(address _collection, uint256 _tokenId, uint256 timestamp, string _tokenURI, address owner);
  event MarketItemCreated(
    address indexed _creator,
    address indexed _collection,
    uint256 _tokenId,
    address _currency,
    uint256 _PriceInEther,
    bytes32 _marketItemId,
    uint256 timestamp
  );
  event MarketItemCancelled(bytes32 marketId, uint256 timestamp);
  event SaleMade(
    bytes32 marketId,
    address indexed _seller,
    address indexed _buyer,
    uint256 indexed _tokenId,
    address _collection,
    address _paymentToken,
    uint256 _amount,
    uint256 timestamp
  );
  event OrderMade(
    address _creator,
    address _recipient,
    address _collection,
    uint256 _tokenId,
    address _token,
    uint256 _bidAmount
  );
  event OrderItemEnded(bytes32 orderId, uint256 timestamp);
  event OrderItemCancelled(bytes32 orderId, uint256 timestamp);
  event OrderItemRejected(bytes32 orderId, uint256 timestamp);

  struct MarketItem {
    address _creator;
    address payable _paymentReceiver;
    uint256 _tokenId;
    address _currency;
    uint256 _price;
    address _collection;
    MarketItemStatus _status;
  }

  struct OfferItem {
    address _creator;
    address _recipient;
    address _collection;
    uint256 _tokenId;
    address _token;
    uint256 _bidAmount;
    OrderItemStatus _status;
  }
}
