pragma solidity ^0.8.0;

interface IMarketPlace {
  event BidCreated(address indexed _createdBy, uint256 timestamp, uint256 _totalBidsMade);
}
