// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VotingPowerToken.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 创建一个模拟的BuilderNFT合约用于测试
contract MockBuilderNFT is ERC721 {
    constructor() ERC721("MockBuilder", "MB") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}

contract VotingPowerTokenTest is Test {
    VotingPowerToken public votingToken;
    MockBuilderNFT public mockNFT;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // 部署模拟的NFT合约
        mockNFT = new MockBuilderNFT();

        // 部署投票权Token合约
        votingToken = new VotingPowerToken(address(mockNFT));
    }

    function testInitialState() public {
        assertEq(votingToken.currentSeason(), 11);
        assertEq(address(votingToken.builderNFT()), address(mockNFT));
    }

    function testSetCurrentSeason() public {
        uint256 newSeason = 12;
        votingToken.setCurrentSeason(newSeason);
        assertEq(votingToken.currentSeason(), newSeason);
    }

    function testSetCurrentSeasonRevert() public {
        uint256 invalidSeason = 10;
        vm.expectRevert("New season must be greater than current");
        votingToken.setCurrentSeason(invalidSeason);
    }

    function testSetCurrentSeasonNotOwner() public {
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                user1
            )
        );
        votingToken.setCurrentSeason(12);
        vm.stopPrank();
    }

    function testMintWithoutNFT() public {
        vm.prank(user1);
        vm.expectRevert("Must own a Builder NFT to mint");
        votingToken.mint();
    }

    function testMintWithNFT() public {
        // 给用户铸造一个BuilderNFT
        mockNFT.mint(user1, 1);

        vm.prank(user1);
        votingToken.mint();

        assertEq(votingToken.balanceOf(user1, votingToken.currentSeason()), 1);
    }

    function testHasBuilderNFT() public {
        assertFalse(votingToken.hasBuilderNFT(user1));

        mockNFT.mint(user1, 1);

        assertTrue(votingToken.hasBuilderNFT(user1));
    }

    function testMintBatch() public {
        vm.expectRevert("Batch minting is not allowed");
        votingToken.mintBatch();
    }

    function testBalanceOf() public {
        mockNFT.mint(user1, 1);
        vm.prank(user1);
        votingToken.mint();
        assertEq(votingToken.balanceOf(user1, votingToken.currentSeason()), 1);
    }
}
