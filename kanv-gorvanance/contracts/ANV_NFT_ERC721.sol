// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./access/Ownable.sol";
import "./token/ERC165.sol";
import "./token/ERC721.sol";
import "./token/IERC721Metadata.sol";
import "./token/IERC721Receiver.sol";
import "./token/IERC165.sol";
import "./token/IERC721.sol";
import "./address/Address.sol";
import "./strings/Strings.sol";



contract ANV_NFT is ERC721, Ownable {

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    constructor (string memory name , string memory symbol)
    ERC721(name, symbol)
    {

    }

    /**
    * create NFT token
    */
    function mint(
        address _to,
        uint256 _tokenId,
        string memory  _IPFSHASH
    ) public virtual onlyOwner
    {
        super._mint(_to, _tokenId);
        super._setIPFSHASH(_tokenId, _IPFSHASH);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze)  public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    
}