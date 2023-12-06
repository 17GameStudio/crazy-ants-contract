// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.9.0;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "../chainlink/v0.8/shared/access/ConfirmedOwner.sol";
import "../chainlink/v0.8/vrf/VRFV2WrapperConsumerBase.sol";

import "../definition/CrazyAntsDefine_Part.sol";
import "../interface/ITokenAntPart.sol";
import "../interface/IPartAttributeComponent.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
contract WithdrawPartModuleV1 is EIP712, VRFV2WrapperConsumerBase, ConfirmedOwner
{
    event event_WithdrawResult(address indexed ownerAddr, uint64 timestamp, uint256 requestId, uint64 indexed identificationID, uint32 num);

    using Counters for Counters.Counter;

    //chain link
    address constant LINK_TOKEN_ADDRESS             = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address constant LINK_WRAPPER_ADDRESS           = 0x99aFAf084eBA697E584501b8Ed2c0B37Dd136693;
    uint32 constant LINK_CALLBACK_GASLIMIT          = 1000000;
    uint16 constant LINK_REQUEST_CONFIRMATIONS      = 3;
    uint16 constant LINK_REQUEST_NUM_WORDS          = 2;

    struct WithdrawPartData
    {
        address PartOwner;
        uint8 PartType;
        uint8 PartQuality;
    }

    address private m_Signer;
    bool private m_Suspend;
    mapping(uint256 => WithdrawPartData) m_WithdrawPartList;

    ITokenAntPart private immutable m_TokenAntPart;
    IPartAttributeComponent private immutable m_PartAttributeComponentInterface;
    
    mapping(address => Counters.Counter) private _nonces;
    bytes32 immutable private _WITHDRAW_PART_TYPEHASH = keccak256("withdrawPart(address signer,address to,uint256 mintData,uint256 nonce)");

    constructor(address partTokenAddr, address partAttrComponentAddr) EIP712("WithdrawPartModuleV1", "1") ConfirmedOwner(msg.sender) VRFV2WrapperConsumerBase(LINK_TOKEN_ADDRESS, LINK_WRAPPER_ADDRESS)
    {
        m_TokenAntPart  = ITokenAntPart(partTokenAddr);
        m_PartAttributeComponentInterface = IPartAttributeComponent(partAttrComponentAddr);

        m_Signer = 0xBd3C86f22f97B580389D8e0598529662eC047F26;
        m_Suspend = false;
    }

    fallback() payable external {}
    receive() payable external {}

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function withdrawPart(uint256 withdrawData, uint8 v, bytes32 r, bytes32 s) external
    {
        require(m_Suspend == false, "suspend !");
        
        uint64 identificationID     = uint64((withdrawData >> 88) & 0xffffffffffffffff);
        uint64 deadline             = uint64((withdrawData >> 24) & 0xffffffffffffffff);
        uint8 partType              = uint8((withdrawData >> 16) & 0xff);
        uint8 partQuality           = uint8((withdrawData >> 8) & 0xff);

        require(block.timestamp <= deadline, "withdraw part expired deadline");
        require(partType >= PART_TYPE_BODY && partType <= PART_TYPE_WEAPON, "part type err !");
        require(partQuality <= MAX_PART_QUALITY, "part quality err !");
        
        bytes32 structHash = keccak256(abi.encode(_WITHDRAW_PART_TYPEHASH, m_Signer, msg.sender, withdrawData, _useNonce(msg.sender)));
        require(_verificationSign(structHash, v, r, s), "mint part invalid signature");

        uint256 requestId = requestRandomness(LINK_CALLBACK_GASLIMIT, LINK_REQUEST_CONFIRMATIONS, LINK_REQUEST_NUM_WORDS);

        m_WithdrawPartList[requestId] = WithdrawPartData(msg.sender, partType, partQuality);

        emit event_WithdrawResult(msg.sender, uint64(block.timestamp), requestId, identificationID, 1);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function setSigner(address addr) public onlyOwner
    {
        require(addr != address(0), "signer address err !");
        m_Signer = addr;
    }

    function setSuspend(bool s) public onlyOwner
    {
        m_Suspend = s;
    }

    function withdrawLink() public onlyOwner
    {
        LinkTokenInterface link = LinkTokenInterface(LINK_TOKEN_ADDRESS);
        
        require
        (
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function _useNonce(address owner) internal returns (uint256 current)
    {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    function _verificationSign(bytes32 structHash, uint8 v, bytes32 r, bytes32 s) view internal returns(bool)
    {
        bytes32 hashData = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hashData, v, r, s);
        if(signer == m_Signer)
        {
            return true;
        }

        return false;
    }

    function nonces(address owner) public view virtual returns (uint256)
    {
        return _nonces[owner].current();
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32)
    {
        return _domainSeparatorV4();
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override
    {
        WithdrawPartData storage withdrawData = m_WithdrawPartList[requestId];
        uint256 randomKey1 = randomWords[0];
        uint256 randomKey2 = randomWords[1];

        require(withdrawData.PartOwner != address(0), "chainlink requestId err !");
        require(randomKey1 > 0 && randomKey2 > 0, "chainlink randomWords err !");

        uint256 partType = withdrawData.PartType;
        uint256 partDisplay;

        if(partType == PART_TYPE_BODY || partType == PART_TYPE_HAND)
        {
            partDisplay = 11 + randomKey1 % 5;    //11~15
        }
        else if(partType == PART_TYPE_ANTENNA || partType == PART_TYPE_HEAD || partType == PART_TYPE_EYE)
        {
            partDisplay = 11 + randomKey1 % 15;   //11~25
        }
        else if(partType == PART_TYPE_WEAPON)
        {
            partDisplay = 1 + randomKey1 % 24;    //1~24
        }

        bytes memory partAttribute = m_PartAttributeComponentInterface.getPartRandomAttribute(randomKey2, uint8(partType), withdrawData.PartQuality);

        Part memory newPart = Part({
                                        TokenID:        0,
                                        TokenOwner:     withdrawData.PartOwner,
                                        Display:        uint8(partDisplay),
                                        Type:           uint8(partType),
                                        Quality:        withdrawData.PartQuality,
                                        Attributes:     partAttribute
                                    });

        delete m_WithdrawPartList[requestId];

        m_TokenAntPart.mint(newPart);
    }
}
