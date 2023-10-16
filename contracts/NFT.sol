// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Referral.sol";

interface IPaymentEngine {
    function buyGS50(uint256 id) external payable;
}

contract ERC721NFT is Referral, ERC721Enumerable {
    IERC20 GS50;

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    uint256 public price;
    uint256 public maxSupply;

    string public baseTokenURI;
    bool public publicMint;

    IPaymentEngine paymentEngine;

    uint256 public _idForPaymentEngine;

    constructor(
        bool _publicMint,
        uint256 _maxSupply,
        uint256 _price,
        string memory _baseTokenURI,
        uint256 _referralBonus,
        uint256 _decimals,
        address _paymentEngineAdd,
        address _GS50Address
    ) ERC721("ReferralNFT", "RNFT") Referral(_referralBonus, _decimals) {
        publicMint = _publicMint;
        maxSupply = _maxSupply;
        setBaseURI(_baseTokenURI);
        price = _price;
        paymentEngine = IPaymentEngine(_paymentEngineAdd);
        _idForPaymentEngine = 0;
        GS50 = IERC20(_GS50Address);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function buyMint(uint _count, bytes32 _referralCode) external payable {
        uint256 totalMinted = _tokenIds.current();
        require(publicMint, "ERROR: Public mint has not started");
        require(totalMinted.add(_count) <= maxSupply, "Not enough NFTs!");
        require(
            msg.value >= price.mul(_count),
            "Not enough ether to purchase NFTs."
        );
        if (msg.value > price.mul(_count))
            payable(msg.sender).transfer(msg.value - price.mul(_count));

        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }

        if (totalMinted == 0) {
            generateReferralCode(msg.sender);
            paymentEngine.buyGS50{value: msg.value}(_idForPaymentEngine);
            GS50.transfer(_msgSender(), GS50.balanceOf(address(this)));
            return;
        }

        generateReferralCode(msg.sender);
        address referrer = referralCodeToAddress[_referralCode];
        console.log("user", msg.sender);
        console.log("referrer", referrer);
        if (referrer != address(0)) {
            require(
                balanceOf(referrer) > 0,
                "Referrer is no longer NFT holder!"
            );
            payReferral(referrer, price.mul(_count));
        }

        paymentEngine.buyGS50{value: msg.value}(_idForPaymentEngine);
        GS50.transfer(_msgSender(), GS50.balanceOf(address(this)));
    }

    function adminMint(uint256 reservedNFT) external onlyOwner {
        uint totalMinted = _tokenIds.current();
        require(totalMinted.add(reservedNFT) < maxSupply, "Not enough NFTs");
        for (uint i = 0; i < reservedNFT; i++) {
            _mintSingleNFT();
        }
        // paymentEngine.buyGS50{value: msg.value}(_idForPaymentEngine);
        // GS50.transfer(_msgSender(), GS50.balanceOf(address(this)));
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _mintSingleNFT() private {
        uint newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }

    function tokensOfOwner(
        address _owner
    ) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setPublicMint(bool _publicMint) external onlyOwner {
        publicMint = _publicMint;
    }
}
