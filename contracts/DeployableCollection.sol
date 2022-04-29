pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './interfaces/IDeployableCollection.sol';

contract DeployableCollection is Context, IDeployableCollection, ERC721URIStorage, ReentrancyGuard, AccessControl {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;
  address public _collectionOwner;
  bytes32 public constant MOD_ROLE = keccak256(abi.encode('MOD'));
  bytes32 public _category;

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'ONLY_ADMINS');
    _;
  }

  modifier onlyMod() {
    require(hasRole(MOD_ROLE, _msgSender()), 'ONLY_MODS');
    _;
  }

  constructor(
    string memory name_,
    string memory symbol_,
    address collectionOwner_,
    string memory category_
  ) ERC721(name_, symbol_) {
    _collectionOwner = collectionOwner_;
    _category = keccak256(abi.encode(category_));
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setRoleAdmin(MOD_ROLE, DEFAULT_ADMIN_ROLE);
  }

  function mintFor(string memory _tokenURI, address to) external onlyMod returns (uint256 _tokenId) {
    _tokenIds.increment();
    _tokenId = _tokenIds.current();
    _mint(to, _tokenId);
    _setTokenURI(_tokenId, _tokenURI);
  }

  function burnFor(uint256 _tokenId) external onlyMod {
    require(_exists(_tokenId), 'TOKEN_DOES_NOT_EXIST');
    _burn(_tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function _addMod(address _mod) external onlyAdmin returns (bool) {
    _grantRole(MOD_ROLE, _mod);
    return true;
  }
}
