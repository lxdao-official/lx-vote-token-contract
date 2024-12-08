// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/LXDAOSeasonalToken.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// 创建一个模拟的 BuilderNFT 合约用于测试
contract MockBuilderNFT is ERC721 {
    constructor() ERC721("MockBuilder", "MB") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}

contract LXDAOSeasonalTokenTest is Test {
    LXDAOSeasonalToken public token;
    MockBuilderNFT public builderNFT;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // 部署模拟的 BuilderNFT
        builderNFT = new MockBuilderNFT();

        // 部署季度代币合约
        token = new LXDAOSeasonalToken(address(builderNFT));
    }

    function testInitialState() public {
        assertEq(token.name(), "LXDAO Seasonal Token");
        assertEq(token.symbol(), "LXST");
        assertEq(token.CLAIM_AMOUNT(), 1);
    }

    function testClaimRequiresBuilderNFT() public {
        vm.startPrank(user1);
        vm.expectRevert("Must be a Builder NFT holder");
        token.claim();
        vm.stopPrank();
    }

    function testSuccessfulClaim() public {
        // 给用户铸造 BuilderNFT
        builderNFT.mint(user1, 1);

        vm.startPrank(user1);
        token.claim();
        assertEq(token.balanceOf(user1), token.CLAIM_AMOUNT());
        vm.stopPrank();
    }

    function testCannotClaimTwiceInSamePeriod() public {
        builderNFT.mint(user1, 1);

        vm.startPrank(user1);
        token.claim();

        vm.expectRevert("Already claimed this period");
        token.claim();
        vm.stopPrank();
    }

    function testBurnAllTokens() public {
        // 给两个用户铸造 NFT 并领取代币
        builderNFT.mint(user1, 1);
        builderNFT.mint(user2, 2);

        vm.prank(user1);
        token.claim();
        assertEq(token.balanceOf(user1), token.CLAIM_AMOUNT());

        vm.prank(user2);
        token.claim();
        assertEq(token.balanceOf(user2), token.CLAIM_AMOUNT());

        uint256 totalSupplyBefore = token.totalSupply();
        assertEq(totalSupplyBefore, 2); // 两个用户各领取1代币

        // 销毁所有代币
        token.burnAllTokens();

        assertEq(token.totalSupply(), 0);
    }

    function testCannotTransfer() public {
        builderNFT.mint(user1, 1);
        address nonBuilder = makeAddr("nonBuilder");

        vm.prank(user1);
        token.claim();

        vm.startPrank(user1);
        vm.expectRevert("Token transfers are not allowed");
        token.transfer(nonBuilder, 1);
        vm.stopPrank();
    }

    function testClaimAfterBurn() public {
        builderNFT.mint(user1, 1);

        vm.startPrank(user1);
        token.claim();
        // 销毁代币
        vm.stopPrank();
        token.burnAllTokens();

        // 用户应该能够在新的周期再次领取
        vm.prank(user1);
        token.claim();
        assertEq(token.balanceOf(user1), token.CLAIM_AMOUNT());
    }

    function testBurnToken() public {
        // 给用户铸造代币
        builderNFT.mint(user1, 1);
        vm.prank(user1);
        token.claim();
        
        // 测试用户销毁自己的代币
        vm.prank(user1);
        token.burnToken(1, user1);
        assertEq(token.balanceOf(user1), 0);
        
        // 测试 owner 销毁指定地址的代币
        vm.prank(user1);
        token.claim();
        token.burnToken(1, user1);
        assertEq(token.balanceOf(user1), 0);
    }

    function testBurnTokenFailures() public {
        builderNFT.mint(user1, 1);
        vm.prank(user1);
        token.claim();
        
        // 测试销毁金额为 0
        vm.expectRevert("Amount must be greater than 0");
        vm.prank(user1);
        token.burnToken(0, user1);
        
        // 测试余额不足
        vm.expectRevert("Insufficient balance");
        vm.prank(user1);
        token.burnToken(2, user1);
    }

    function testIsBuilder() public {
        // 测试无 NFT 的情况
        assertFalse(token.isBuilder(user1));
        
        // 测试持有一个 NFT
        builderNFT.mint(user1, 1);
        assertTrue(token.isBuilder(user1));
        
        // 测试持有多个 NFT
        builderNFT.mint(user1, 2);
        assertTrue(token.isBuilder(user1));
    }

    function testDecimals() public {
        assertEq(token.decimals(), 0);
    }
}
