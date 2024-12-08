// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract VotingPowerToken is ERC1155, Ownable {
    uint256 public currentSeason;
    IERC721 public builderNFT;

    // 构造函数设置NFT合约地址
    constructor(address _builderNFTAddress) ERC1155("") Ownable(msg.sender) {
        builderNFT = IERC721(_builderNFTAddress);
        currentSeason = 11; // 从第一季开始
    }

    // 管理员可以设置当前season
    function setCurrentSeason(uint256 _newSeason) external onlyOwner {
        require(
            _newSeason > currentSeason,
            "New season must be greater than current"
        );
        currentSeason = _newSeason;
    }

    // 检查用户是否持有BuilderNFT
    function hasBuilderNFT(address _user) public view returns (bool) {
        return builderNFT.balanceOf(_user) > 0;
    }

    // mint当前season的投票权token
    function mint() external {
        require(hasBuilderNFT(msg.sender), "Must own a Builder NFT to mint");

        // currentSeason作为tokenId
        _mint(msg.sender, currentSeason, 1, "");
    }

    // 可选：批量mint功能
    function mintBatch() external pure {
        revert("Batch minting is not allowed");
    }
}
