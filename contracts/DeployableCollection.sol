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
  bytes32 public constant MOD_ROLE = keccak256('MOD');

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
    address collectionOwner_
  ) ERC721(name_, symbol_) {
    _collectionOwner = collectionOwner_;
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setRoleAdmin(MOD_ROLE, DEFAULT_ADMIN_ROLE);
  }

  function mintFor(string memory _tokenURI, address to) external onlyMod returns (uint256 _tokenId) {
    _tokenIds.increment();
    _tokenId = _tokenIds.current();
    _mint(to, _tokenId);
    _setTokenURI(_tokenId, _tokenURI);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
