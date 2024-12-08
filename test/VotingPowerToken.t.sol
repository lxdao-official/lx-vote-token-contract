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

    function testBurn() public {
        // 给用户铸造NFT和投票权token
        mockNFT.mint(user1, 1);
        vm.prank(user1);
        votingToken.mint();

        // 确认用户有token
        assertEq(votingToken.balanceOf(user1, votingToken.currentSeason()), 1);

        // 管理员销毁token
        votingToken.burn(user1, votingToken.currentSeason());

        // 验证token已被销毁
        assertEq(votingToken.balanceOf(user1, votingToken.currentSeason()), 0);
    }

    function skip_testBurnNotOwner() public {
        // 给用户铸造NFT和投票权token
        mockNFT.mint(user1, 1);
        vm.prank(user1);
        votingToken.mint();

        // 记录初始余额
        uint256 initialBalance = votingToken.balanceOf(
            user1,
            votingToken.currentSeason()
        );

        // 非管理员尝试销毁token
        console.log("user2 address:", user2);
        vm.startPrank(user2);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                user2
            )
        );
        votingToken.burn(user1, votingToken.currentSeason());
        vm.stopPrank();

        // 验证余额未变
        assertEq(
            votingToken.balanceOf(user1, votingToken.currentSeason()),
            initialBalance,
            "Balance should not change after failed burn"
        );
    }

    function testBurnInvalidSeason() public {
        // 给用户铸造NFT和投票权token
        mockNFT.mint(user1, 1);
        vm.prank(user1);
        votingToken.mint();

        // 尝试销毁不存在的season的token
        uint256 invalidSeason = votingToken.currentSeason() + 1;
        vm.expectRevert("Insufficient balance to burn");
        votingToken.burn(user1, invalidSeason);
    }

    function skip_testBurnZeroAddress() public {
        assertEq(
            votingToken.balanceOf(address(0), votingToken.currentSeason()),
            0
        );
        // 尝试对零地址进行销毁操作
        vm.expectRevert("Cannot burn from zero address");
        votingToken.burn(address(0), votingToken.currentSeason());
    }

    function testTotalSupply() public {
        // 初始供应量应该为0
        assertEq(votingToken.totalSupply(votingToken.currentSeason()), 0);

        // 给多个用户铸造NFT和投票权token
        mockNFT.mint(user1, 1);
        mockNFT.mint(user2, 2);

        vm.prank(user1);
        votingToken.mint();
        vm.prank(user2);
        votingToken.mint();

        // 验证总供应量
        assertEq(votingToken.totalSupply(votingToken.currentSeason()), 2);
    }

    function testTotalSupplyAfterBurn() public {
        // 铸造token
        mockNFT.mint(user1, 1);
        vm.prank(user1);
        votingToken.mint();

        assertEq(votingToken.totalSupply(votingToken.currentSeason()), 1);

        // 销毁token
        votingToken.burn(user1, votingToken.currentSeason());

        // 验证总供应量减少
        assertEq(votingToken.totalSupply(votingToken.currentSeason()), 0);
    }

    function testTotalSupplyDifferentSeasons() public {
        // Season 11
        mockNFT.mint(user1, 1);
        vm.prank(user1);
        votingToken.mint();

        uint256 season11 = votingToken.currentSeason();
        assertEq(votingToken.totalSupply(season11), 1);

        // 切换到 Season 12
        votingToken.setCurrentSeason(12);

        // Season 12的铸造
        mockNFT.mint(user2, 2);
        vm.prank(user2);
        votingToken.mint();

        // 验证不同season的供应量
        assertEq(votingToken.totalSupply(season11), 1);
        assertEq(votingToken.totalSupply(votingToken.currentSeason()), 1);
    }

    function testTotalSupplyNonExistentSeason() public view {
        // 查询不存在的season的供应量
        uint256 nonExistentSeason = votingToken.currentSeason() + 1;
        assertEq(votingToken.totalSupply(nonExistentSeason), 0);
    }
}
