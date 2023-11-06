// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "../../interface/ITokenPet.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
contract CrazyAntsPet is ERC721, ERC721Enumerable, ERC2981, ITokenPet
{
    using Strings for uint256;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    event event_CreatePet(address indexed ownerAddr, uint64 timestamp, uint256 indexed tokenID, Pet petData);
    event event_DestroyPet(address indexed ownerAddr, uint64 timestamp, uint256 indexed tokenID);
    event event_TransferPet(address indexed ownerAddr, uint64 timestamp, uint256 indexed tokenID, address indexed toAddr);
    event event_UpdatePet(address indexed ownerAddr, uint64 timestamp, uint256 indexed tokenID, Pet petData);

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    uint256 private m_PetTokenID = 100;
    string private m_PetBaseURI = "https://static.crazyants.online/pet/";

    address private m_Owner;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    mapping(address => uint256) private m_GameAdmin;
    mapping(uint256 => Pet) private m_PetList;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    constructor() ERC721("Crazy Ants Pet", "PET")
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
    function getPetData(uint256 tokenID) view external returns(Pet memory)
    {
        return m_PetList[tokenID];
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function mint(address ownerAddr, uint256 petID, uint256[][SKILL_MAX_TYPE] calldata skills) external onlyAdmin returns(uint256)
    {
        uint256 token_id = (++m_PetTokenID);
        _safeMint(ownerAddr, token_id);

        Pet storage newPet = m_PetList[token_id];
        {
            newPet.TokenID      = uint64(token_id);
            newPet.TokenOwner   = ownerAddr;
            newPet.PetID        = uint32(petID);
            newPet.Birthday     = uint64(block.timestamp);
            newPet.Level        = 1;
            newPet.BaseAttr     = 0;
            
            for(uint256 m = 0; m < SKILL_MAX_TYPE; ++m)
            {
                for(uint256 n = 0; n < skills[m].length; ++n)
                {
                    newPet.Skills[m].push(uint32(skills[m][n]));
                }
            }
        }

        emit event_CreatePet(ownerAddr, uint64(block.timestamp), token_id, newPet);
        return token_id;
    }

    function burn(uint256 tokenID) external onlyAdmin
    {
        require(_isApprovedOrOwner(_msgSender(), tokenID), "caller is not owner nor approved !");

        address owner = ownerOf(tokenID);

        emit event_DestroyPet(owner, uint64(block.timestamp), tokenID);

        _burn(tokenID);
        delete m_PetList[tokenID];
    }

    function setPetData(address ownerAddr, uint256 tokenID, uint256 dataType, uint256 dataValue) onlyAdmin external
    {
        require(_isApprovedOrOwner(ownerAddr, tokenID), "caller is not owner nor approved !");
        require(_exists(tokenID), "invalid token id");

        Pet storage petData = m_PetList[tokenID];
        {
            if(dataType == 1)
            {
                petData.Level = uint32(dataValue);
            }
            else if(dataType == 2)
            {
                petData.BaseAttr = uint160(dataValue);
            }
        }

        emit event_UpdatePet(ownerAddr, uint64(block.timestamp), tokenID, petData);
    }

    function setPetSkill(address ownerAddr, uint256 tokenID, uint256 skillType, uint256 skillIndex, uint256 skillID) onlyAdmin external
    {
        require(_isApprovedOrOwner(ownerAddr, tokenID), "caller is not owner nor approved !");
        require(_exists(tokenID), "invalid token id");
        require(skillType < SKILL_MAX_TYPE, "pet skill type err !");

        Pet storage petData = m_PetList[tokenID];
        {
            if(skillIndex != SKILL_MAX_INDEX)
            {
                require(skillIndex < petData.Skills[skillType].length, "pet skill index err !");
                petData.Skills[skillType][skillIndex] = uint32(skillID);
            }
            else
            {
                petData.Skills[skillType].push(uint32(skillID));
            }
        }

        emit event_UpdatePet(ownerAddr, uint64(block.timestamp), tokenID, petData);
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
        m_PetBaseURI = baseURI;
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
        return (super._exists(tokenID) && m_PetList[tokenID].TokenID != 0);
    }

    function _transfer(address from, address to, uint256 tokenID) internal override
    {
        super._transfer(from, to, tokenID);

        Pet storage pet = m_PetList[tokenID];
        
        if(pet.TokenID != 0)
        {
            pet.TokenOwner = to;
        }

        emit event_TransferPet(from, uint64(block.timestamp), tokenID, to);
    }

    function tokenURI(uint256 tokenID) public view override returns (string memory)
    {
        require(_exists(tokenID), "invalid token id");
        return string(abi.encodePacked(m_PetBaseURI, tokenID.toString(), "/meta_data.json"));
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
