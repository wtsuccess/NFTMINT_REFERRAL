// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Referral is Ownable {
    using SafeMath for uint256;

    uint256 public referralBonus;
    uint256 public decimals;

    mapping(address => bytes32) public addressToReferralCode;
    mapping(bytes32 => address) public referralCodeToAddress;

    event RegisteredReferralCode(address referee, bytes32 referralCode);
    event PaidReferral(address from, address to, uint amount);

    constructor(uint256 _referralBonus, uint256 _decimals) {
        referralBonus = _referralBonus;
        decimals = _decimals;
    }

    function payReferral(
        address referrer,
        uint256 value
    ) internal returns (uint256) {
        uint256 totalReferal = (value.mul(referralBonus)).div(decimals);
        payable(referrer).transfer(totalReferal);
        emit PaidReferral(msg.sender, referrer, totalReferal);
        return totalReferal;
    }

    function generateReferralCode(address addr) public {
        bytes32 referralCode = generateUniqueReferralCode(addr);
        addressToReferralCode[addr] = referralCode;
        referralCodeToAddress[referralCode] = addr;
    }

    function generateUniqueReferralCode(
        address addr
    ) internal pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(addr));
        return hash;
    }

    function addReferrer(bytes32 referralCode) internal returns (bool) {
        referralCodeToAddress[referralCode] = msg.sender;
        emit RegisteredReferralCode(msg.sender, referralCode);
        return true;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function setReferralBonus(uint256 _referralBonus) external onlyOwner {
        referralBonus = _referralBonus;
    }
}
