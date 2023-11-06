// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.9.0;

import "../definition/CrazyAntsStruct_Ant.sol";
import "../definition/CrazyAntsStruct_Attribute.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITokenAnt is IERC721
{
    function getAntData(uint256 tokenID) view external returns(Ant memory);
    function getAntDataByIndex(address ownerAddr, uint256 tokenIndex) view external returns(Ant memory);

    function getAntAttribute(uint256 tokenID) view external returns(Attribute[] memory);
    function getAntAttributeValue(uint256 tokenID, uint256 attrID) view external returns(uint256);

    function mint(address ownerAddr, uint32 version, uint64 characteristics, bytes calldata attributes) external returns(uint256);
    function burn(uint256 tokenID) external;

    function appendAntAttribute(address ownerAddr, uint256 tokenID, uint256 attrID, uint256 attrValue) external;
    function changeAntAttribute(address ownerAddr, uint256 tokenID, uint256 attrID, uint256 attrValue) external;
}
