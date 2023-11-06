// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "../../library/BinaryAttribute.sol";
import "../../interface/ITokenAntPart.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////
contract CrazyAntsPart is ERC721, ERC721Enumerable, ERC2981, ITokenAntPart
{
    using Strings for uint256;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    event event_CreatePart(address indexed ownerAddr, uint256 indexed tokenID, Part partData);
    event event_DestroyPart(address indexed ownerAddr, uint256 indexed tokenID);
    event event_TransferPart(address indexed ownerAddr, uint256 indexed tokenID, address indexed toAddr);

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    uint256 private m_PartTokenID = 1000;
    string private m_PartBaseURI = "https://static.crazyants.online/part/";

    address private m_Owner;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    mapping(address => uint256) private m_GameAdmin;
    mapping(uint256 => Part) private m_PartList;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    constructor() ERC721("Crazy Ants Part", "CAP")
    {
        m_Owner = 0xCD1A93C52624f2a5142691632Ee57466D08C1245;

        _setDefaultRoyalty(0x5B7e9AD6766d92988AC5e80Cc6742ec207F6E68E, 500);
    }

    modifier onlyOwner()
    {
        require(m_Owner == _msgSender(), "permission denied !");
        _;
    }

    modifier onlyAdmin()
    {
        require(m_GameAdmin[_msgSender()] > 0, "permission denied !");
        _;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function getPartData(uint256 tokenID) view external returns(Part memory)
    {
        return m_PartList[tokenID];
    }

    function getPartDataByIndex(address ownerAddr, uint256 tokenIndex) view external override returns(Part memory)
    {
        uint256 tokenID = tokenOfOwnerByIndex(ownerAddr, tokenIndex);
        return m_PartList[tokenID];
    }

    function getPartAttribute(uint256 tokenID) view external returns(Attribute[] memory)
    {
        return BinaryAttribute.deserializeAttributes(m_PartList[tokenID].Attributes);
    }
    
    function getPartAttributeValue(uint256 tokenID, uint256 attrID) view external returns(uint256)
    {
        return BinaryAttribute.getAttributeValue(m_PartList[tokenID].Attributes, attrID);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function mint(Part memory newPart) external onlyAdmin
    {
        uint256 token_id = (++m_PartTokenID);
        _safeMint(newPart.TokenOwner, token_id);

        newPart.TokenID = uint64(token_id);

        m_PartList[newPart.TokenID] = newPart;
        emit event_CreatePart(newPart.TokenOwner, token_id, newPart);
    }

    function burn(uint256 tokenID) external onlyAdmin
    {
        require(_isApprovedOrOwner(_msgSender(), tokenID), "caller is not owner nor approved !");

        address owner = ownerOf(tokenID);

        emit event_DestroyPart(owner, tokenID);

        _burn(tokenID);
        delete m_PartList[tokenID];
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function setOwner(address newAddr) external onlyOwner
    {
        require(newAddr != address(0), "owner address err !");
        m_Owner = newAddr;
    }

    function setGameAdmin(address adminAddr, uint256 actived) external onlyOwner
    {
        require(adminAddr != address(0), "admin address err !");
        m_GameAdmin[adminAddr] = actived;
    }

    function setBaseTokenURI(string calldata baseURI) external onlyOwner
    {
        m_PartBaseURI = baseURI;
    }

    function setRoyalty(address receiver, uint96 feeNumerator) external onlyOwner
    {
        if(receiver != address(0))
        {
            _setDefaultRoyalty(receiver, feeNumerator);
        }
        else
        {
            _deleteDefaultRoyalty();
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function _exists(uint256 tokenID) internal view override returns (bool)
    {
        return (super._exists(tokenID) && m_PartList[tokenID].TokenID != 0);
    }

    function _transfer(address from, address to, uint256 tokenID) internal override
    {
        super._transfer(from, to, tokenID);

        Part storage part = m_PartList[tokenID];
        
        if(part.TokenID != 0)
        {
            part.TokenOwner = to;
        }

        emit event_TransferPart(from, tokenID, to);
    }

    function tokenURI(uint256 tokenID) public view override returns (string memory)
    {
        require(_exists(tokenID), "invalid token id");
        return string(abi.encodePacked(m_PartBaseURI, tokenID.toString(), "/meta_data.json"));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC2981, IERC165) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
}
