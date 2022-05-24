pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract TestERC20 is ERC20 {
  constructor(uint256 totalSupply_) ERC20('TestToken', 'TT') {
    _mint(msg.sender, totalSupply_);
  }
}
