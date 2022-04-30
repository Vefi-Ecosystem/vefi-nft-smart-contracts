pragma solidity ^0.8.0;

interface IMarketPlace {
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
  event BidUpdated(uint256 indexed _tokenId, uint256 _newPrice, uint256 timestamp);
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
    address _currency;
    uint256 _price;
    bool _finalized;
  }
}
