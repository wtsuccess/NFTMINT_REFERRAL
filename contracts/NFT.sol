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
    uint256 public _idForPaymentEngine;

    mapping(address => bool) public administrators;

    string public baseTokenURI;
    bool public publicMint;

    IPaymentEngine paymentEngine;

    constructor(
        string memory _baseTokenURI,
        uint256 _referralBonus,
        uint256 _decimals,
        address _paymentEngineAdd,
        address _GS50Address
    ) ERC721("ReferralNFT", "RNFT") Referral(_referralBonus, _decimals) {
        price = 0.01 ether;
        publicMint = true;
        maxSupply = 100;
        setBaseURI(_baseTokenURI);
        paymentEngine = IPaymentEngine(_paymentEngineAdd);
        _idForPaymentEngine = 0;
        GS50 = IERC20(_GS50Address);
    }

    function buyMint(uint256 _count, bytes32 _referralCode) external payable {
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

        generateReferralCode(msg.sender);
        if (_referralCode == bytes32(0)) {
            paymentEngine.buyGS50{value: msg.value}(_idForPaymentEngine);
            GS50.transfer(_msgSender(), GS50.balanceOf(address(this)));
            return;
        }

        address referrer = referralCodeToAddress[_referralCode];
        uint256 totalReferral;
        if (balanceOf(referrer) > 0) {
            totalReferral = payReferral(referrer, price.mul(_count));
        }
        paymentEngine.buyGS50{value: msg.value - totalReferral}(
            _idForPaymentEngine
        );
        GS50.transfer(_msgSender(), GS50.balanceOf(address(this)));
    }

    modifier onlyAdmin() {
        require(administrators[msg.sender], "ERROR: only administrator");
        _;
    }

    function adminMint(uint256 reservedNFT) external onlyAdmin {
        uint totalMinted = _tokenIds.current();
        require(totalMinted.add(reservedNFT) < maxSupply, "Not enough NFTs");
        for (uint i = 0; i < reservedNFT; i++) {
            _mintSingleNFT();
        }
        generateReferralCode(msg.sender);
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function addAdministrators(address _admin) public onlyOwner {
        administrators[_admin] = true;
    }

    function removeAdministrator(address _add) public onlyOwner {
        administrators[_add] = false;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function changePaymentEngine(address _paymentEngineAdd) public onlyOwner {
        paymentEngine = IPaymentEngine(_paymentEngineAdd);
    }

    function changePaymentEngineId(uint256 _newId) public onlyOwner {
        _idForPaymentEngine = _newId;
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
