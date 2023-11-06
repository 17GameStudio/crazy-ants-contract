// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "../../library/BinaryAttribute.sol";
import "../../interface/ITokenAnt.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////
contract AntCore
{
    address private immutable m_Master;
    mapping(uint256 => Ant) private m_AntList;

    //////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////
    constructor(address masterAddr)
    {
        m_Master = masterAddr;
    }

    modifier onlyMaster()
    {
        require(m_Master == msg.sender, "permission denied !");
        _;
    }

    ////////////////////////////////////////////////////////////////////////////////////
    function existAnt(uint256 tokenID) public view returns(bool)
    {
        if (m_AntList[tokenID].TokenID != 0)
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    function getAnt(uint256 tokenID) view public returns(Ant memory)
    {
        require(existAnt(tokenID), "invalid token id");
        return m_AntList[tokenID];
    }

    function getAttribute(uint256 tokenID) view public returns(Attribute[] memory)
    {
        require(existAnt(tokenID), "invalid token id");
        return BinaryAttribute.deserializeAttributes(m_AntList[tokenID].Attributes);
    }

    function getAttributeValue(uint256 tokenID, uint256 attrID) view public returns(uint256)
    {
        require(existAnt(tokenID), "invalid token id");
        return BinaryAttribute.getAttributeValue(m_AntList[tokenID].Attributes, attrID);
    }

    ////////////////////////////////////////////////////////////////////////////////////
    function create(Ant memory newAnt) public onlyMaster
    {
        require(newAnt.Attributes.length > 0, "attribute list err!");
        m_AntList[newAnt.TokenID] = newAnt;
    }

    function destroy(uint256 tokenID) public onlyMaster
    {
        require(existAnt(tokenID), "invalid token id");

        Ant storage antData = m_AntList[tokenID];
        antData.TokenOwner = address(0);
    }

    function transfer(uint256 tokenID, address newAddr) public onlyMaster
    {
        require(existAnt(tokenID), "invalid token id");

        Ant storage antData = m_AntList[tokenID];
        antData.TokenOwner = newAddr;
    }

    function appendAttribute(uint256 tokenID, uint256 attrID, uint256 attrValue) public onlyMaster
    {
        require(existAnt(tokenID), "invalid token id");
        BinaryAttribute.pushAttribute(m_AntList[tokenID].Attributes, attrID, attrValue);
    }

    function changeAttribute(uint256 tokenID, uint256 attrID, uint256 attrValue) public onlyMaster
    {
        require(existAnt(tokenID), "invalid token id");
        BinaryAttribute.setAttribute(m_AntList[tokenID].Attributes, attrID, attrValue);
    }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
contract CrazyAntsRole is ERC721, ERC721Enumerable, ERC2981, ITokenAnt
{
    using Strings for uint256;
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    event event_CreateAnt(address indexed ownerAddr, uint256 indexed tokenID, Ant antData);
    event event_DestroyAnt(address indexed ownerAddr, uint256 indexed tokenID);
    event event_TransferAnt(address indexed ownerAddr, uint256 indexed tokenID, address indexed toAddr);

    event event_AppendAntAttribute(address indexed ownerAddr, uint256 indexed tokenID, uint256 attrID, uint256 attrValue);
    event event_ChangeAntAttribute(address indexed ownerAddr, uint256 indexed tokenID, uint256 attrID, uint256 attrValue);

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    AntCore immutable private m_AntCore;

    address private m_Owner;
    mapping(address => uint256) private m_GameAdmin;

    string private m_AntTokenURI = "https://static.crazyants.online/role/";
    uint256 private m_AntTokenID = 100;
    
    //////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////
    constructor() ERC721("Crazy Ants Role", "ANT")
    {
        m_AntCore = new AntCore(address(this));

        m_Owner = 0xCD1A93C52624f2a5142691632Ee57466D08C1245;
        _setDefaultRoyalty(0x5B7e9AD6766d92988AC5e80Cc6742ec207F6E68E, 500);
    }

    //////////////////////////////////////////////////////////////////////////////////////////
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

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function getAntData(uint256 tokenID) view external override returns(Ant memory)
    {
        return m_AntCore.getAnt(tokenID);
    }

    function getAntDataByIndex(address ownerAddr, uint256 tokenIndex) view external override returns(Ant memory)
    {
        uint256 tokenID = tokenOfOwnerByIndex(ownerAddr, tokenIndex);
        return m_AntCore.getAnt(tokenID);
    }

    function getAntAttribute(uint256 tokenID) view external returns(Attribute[] memory)
    {
        return m_AntCore.getAttribute(tokenID);
    }

    function getAntAttributeValue(uint256 tokenID, uint256 attrID) view external override returns(uint256)
    {
        return m_AntCore.getAttributeValue(tokenID, attrID);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function mint(address ownerAddr, uint32 version, uint64 characteristics, bytes calldata attributes) override external onlyAdmin returns(uint256)
    {
        uint256 token_id = (++m_AntTokenID);
        _safeMint(ownerAddr, token_id);

        Ant memory newAnt = Ant({
                                    TokenID:            uint64(token_id),
                                    TokenOwner:         ownerAddr,
                                    Version:            uint32(version),
                                    Characteristics:    uint64(characteristics),
                                    Birthday:           uint64(block.timestamp),
                                    Attributes:         attributes
                                });

        m_AntCore.create(newAnt);

        emit event_CreateAnt(ownerAddr, token_id, newAnt);
        
        return token_id;
    }

    function burn(uint256 tokenID) external onlyAdmin
    {
        require(_isApprovedOrOwner(_msgSender(), tokenID), "caller is not owner nor approved !");

        address owner = ownerOf(tokenID);

        emit event_DestroyAnt(owner, tokenID);

        _burn(tokenID);
        m_AntCore.destroy(tokenID);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function appendAntAttribute(address ownerAddr, uint256 tokenID, uint256 attrID, uint256 attrValue) override external onlyAdmin
    {
        require(_isApprovedOrOwner(ownerAddr, tokenID), "caller is not owner nor approved !");

        m_AntCore.appendAttribute(tokenID, attrID, attrValue);

        emit event_AppendAntAttribute(ownerAddr, tokenID, attrID, attrValue);
    }

    function changeAntAttribute(address ownerAddr, uint256 tokenID, uint256 attrID, uint256 attrValue) override external onlyAdmin
    {
        require(_isApprovedOrOwner(ownerAddr, tokenID), "caller is not owner nor approved !");

        m_AntCore.changeAttribute(tokenID, attrID, attrValue);

        emit event_ChangeAntAttribute(ownerAddr, tokenID, attrID, attrValue);
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

    function setBaseTokenURI(string calldata baseTokenURI) external onlyOwner
    {
        m_AntTokenURI = baseTokenURI;
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
        return (super._exists(tokenID) && m_AntCore.existAnt(tokenID));
    }

    function _transfer(address from, address to, uint256 tokenID) internal override
    {
        super._transfer(from, to, tokenID);
        m_AntCore.transfer(tokenID, to);

        emit event_TransferAnt(from, tokenID, to);
    }

    function tokenURI(uint256 tokenID) public view override returns (string memory)
    {
        require(_exists(tokenID), "invalid token id");
        return string(abi.encodePacked(m_AntTokenURI, tokenID.toString(), "/meta_data.json"));
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
