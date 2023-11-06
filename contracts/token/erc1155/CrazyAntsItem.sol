// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../../interface/ITokenItem.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////
contract CrazyAntsItem is ERC1155, ERC2981, Pausable, ITokenItem
{
    using Strings for uint256;

    event event_ItemBalance(uint256 timestamp, address indexed account, uint256 indexed id, uint8 quality, uint256 value);

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    string private m_Name;
    address private m_Owner;

    mapping(address => bool) private m_Minter;
    mapping(uint256 => Item) private m_ItemToken;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    constructor() ERC1155("https://static.crazyants.online/item/")
    {
        m_Name = "Crazy Ants Item";

        m_Owner = 0xCD1A93C52624f2a5142691632Ee57466D08C1245;
        _setDefaultRoyalty(0x5B7e9AD6766d92988AC5e80Cc6742ec207F6E68E, 500);

        _setItemToken(1001, 2, "star stone");
    }

    modifier onlyOwner()
    {
        require(m_Owner == _msgSender(), "permission denied !");
        _;
    }

    modifier onlyMinter()
    {
        require(m_Minter[_msgSender()], "permission denied !");
        _;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external onlyMinter
    {
        _mint(to, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external onlyMinter
    {
        _mintBatch(to, ids, amounts, data);
    }

    function burn(address account, uint256 id, uint256 value) external onlyMinter
    {
        require(account == _msgSender() || isApprovedForAll(account, _msgSender()), "caller is not owner nor approved");
        
        _burn(account, id, value);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external onlyMinter
    {
        require(account == _msgSender() || isApprovedForAll(account, _msgSender()), "caller is not owner nor approved");

        _burnBatch(account, ids, values);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function name() external view returns (string memory)
    {
        return m_Name;
    }

    function getItemData(uint256 id) external view returns (Item memory)
    {
        return m_ItemToken[id];
    }

    function uri(uint256 id) public view override returns (string memory)
    {
        require(m_ItemToken[id].ItemID > 0, "invalid token id");

        string memory baseUri = super.uri(0);

        return string(abi.encodePacked(baseUri, id.toString(), "/meta_data.json"));
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, ERC2981, IERC165) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function setURI(string memory newuri) public onlyOwner
    {
        super._setURI(newuri);
    }

    function suspend(bool state) public onlyOwner
    {
        if(state == true)
        {
            super._pause();
        }
        else
        {
            super._unpause();
        }
    }

    function setOwner(address addr) public onlyOwner
    {
        require(addr != address(0), "owner address err !");
        m_Owner = addr;
    }

    function setMinter(address addr, bool enable) public onlyOwner
    {
        require(addr != address(0), "minter address err !");
        m_Minter[addr] = enable;
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

    function setItemToken(uint256 itemID, uint256 itemQuality, string calldata tokenName) external onlyOwner
    {
        _setItemToken(itemID, itemQuality, tokenName);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function _setItemToken(uint256 itemID, uint256 itemQuality, string memory tokenName) internal
    {
        m_ItemToken[itemID] = Item(uint32(itemID), uint8(itemQuality), tokenName);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override
    {
        for (uint256 i = 0; i < ids.length; i++)
        {
            require(m_ItemToken[ids[i]].ItemID > 0, "invalid token id");
        }

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!paused(), "Pausable: token transfer while paused");
    }

    function _afterTokenTransfer(address, address from, address to, uint256[] memory ids, uint256[] memory, bytes memory) internal override
    {
        for (uint256 i = 0; i < ids.length; i++)
        {
            if(from != address(0))
            {
                emit event_ItemBalance(block.timestamp, from, ids[i], m_ItemToken[ids[i]].ItemQuality,  super.balanceOf(from, ids[i]));
            }

            if(to != address(0))
            {
                emit event_ItemBalance(block.timestamp, to, ids[i], m_ItemToken[ids[i]].ItemQuality,  super.balanceOf(to, ids[i]));
            }
        }
    }

}
