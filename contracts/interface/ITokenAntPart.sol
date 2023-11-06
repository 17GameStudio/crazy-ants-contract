// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.9.0;

import "../definition/CrazyAntsStruct_Part.sol";
import "../definition/CrazyAntsStruct_Attribute.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITokenAntPart is IERC721
{
    function getPartData(uint256 tokenID) view external returns(Part memory);
    function getPartDataByIndex(address ownerAddr, uint256 tokenIndex) view external returns(Part memory);

    function getPartAttribute(uint256 tokenID) view external returns(Attribute[] memory);
    function getPartAttributeValue(uint256 tokenID, uint256 attrID) view external returns(uint256);

    function mint(Part memory newPart) external;
    function burn(uint256 tokenID) external;
}
