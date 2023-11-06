// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.9.0;

import "../definition/CrazyAntsStruct_Pet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITokenPet is IERC721
{
    function getPetData(uint256 tokenID) view external returns(Pet memory);

    function mint(address ownerAddr, uint256 petID, uint256[][SKILL_MAX_TYPE] calldata skills) external returns(uint256);
    function burn(uint256 tokenID) external;

    function setPetData(address ownerAddr, uint256 tokenID, uint256 dataType, uint256 dataValue) external;
    function setPetSkill(address ownerAddr, uint256 tokenID, uint256 skillType, uint256 skillIndex, uint256 skillID) external;
}
