// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.9.0;

interface IPartAttributeComponent
{
    function getPartRandomAttribute(uint256 randomKey, uint8 partType, uint8 partQuality) view external returns(bytes memory);

    function randomBaseAttr(uint256 randomKey, uint8 partType, uint8 partQuality) view external returns(bytes memory);
    function randomAttackAttr(uint256 randomKey, uint8 partQuality) view external returns(bytes memory);
    function randomDefenseAttr(uint256 randomKey, uint8 partType, uint8 partQuality) view external returns(bytes memory);
}
