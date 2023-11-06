// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.9.0;

uint8 constant SKILL_TYPE_1 = 0;
uint8 constant SKILL_TYPE_2 = 1;
uint8 constant SKILL_TYPE_3 = 2;

uint8 constant SKILL_MAX_TYPE = 3;
uint32 constant SKILL_MAX_INDEX = 0xffffffff;

struct Pet
{
    uint64 TokenID;
    address TokenOwner;
    uint32 PetID;
    uint64 Birthday;
    uint32 Level;
    uint160 BaseAttr;
    uint32[][SKILL_MAX_TYPE] Skills;
}
