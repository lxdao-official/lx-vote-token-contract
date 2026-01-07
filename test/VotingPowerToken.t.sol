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
        assertEq(votingToken.currentYear(), 2026);
        assertEq(address(votingToken.builderNFT()), address(mockNFT));
    }

    function testSetCurrentYear() public {
        uint256 newYear = 2027;
        votingToken.setCurrentYear(newYear);
        assertEq(votingToken.currentYear(), newYear);
    }

    function testSetCurrentYearRevert() public {
        uint256 invalidYear = 2025;
        vm.expectRevert("New year must be greater than current");
        votingToken.setCurrentYear(invalidYear);
    }

    function testSetCurrentYearNotOwner() public {
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                user1
            )
        );
        votingToken.setCurrentYear(2027);
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

        assertEq(votingToken.balanceOf(user1, votingToken.currentYear()), 1);
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
        assertEq(votingToken.balanceOf(user1, votingToken.currentYear()), 1);
    }

    function testBurn() public {
        // 给用户铸造NFT和投票权token
        mockNFT.mint(user1, 1);
        vm.prank(user1);
        votingToken.mint();

        // 确认用户有token
        assertEq(votingToken.balanceOf(user1, votingToken.currentYear()), 1);

        // 管理员销毁token
        votingToken.burn(user1, votingToken.currentYear());

        // 验证token已被销毁
        assertEq(votingToken.balanceOf(user1, votingToken.currentYear()), 0);
    }

    function skip_testBurnNotOwner() public {
        // 给用户铸造NFT和投票权token
        mockNFT.mint(user1, 1);
        vm.prank(user1);
        votingToken.mint();

        // 记录初始余额
        uint256 initialBalance = votingToken.balanceOf(
            user1,
            votingToken.currentYear()
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
        votingToken.burn(user1, votingToken.currentYear());
        vm.stopPrank();

        // 验证余额未变
        assertEq(
            votingToken.balanceOf(user1, votingToken.currentYear()),
            initialBalance,
            "Balance should not change after failed burn"
        );
    }

    function testBurnInvalidYear() public {
        // 给用户铸造NFT和投票权token
        mockNFT.mint(user1, 1);
        vm.prank(user1);
        votingToken.mint();

        // 尝试销毁不存在的year的token
        uint256 invalidYear = votingToken.currentYear() + 1;
        vm.expectRevert("Insufficient balance to burn");
        votingToken.burn(user1, invalidYear);
    }

    function skip_testBurnZeroAddress() public {
        assertEq(
            votingToken.balanceOf(address(0), votingToken.currentYear()),
            0
        );
        // 尝试对零地址进行销毁操作
        vm.expectRevert("Cannot burn from zero address");
        votingToken.burn(address(0), votingToken.currentYear());
    }

    function testTotalSupply() public {
        // 初始供应量应该为0
        assertEq(votingToken.totalSupply(votingToken.currentYear()), 0);

        // 给多个用户铸造NFT和投票权token
        mockNFT.mint(user1, 1);
        mockNFT.mint(user2, 2);

        vm.prank(user1);
        votingToken.mint();
        vm.prank(user2);
        votingToken.mint();

        // 验证总供应量
        assertEq(votingToken.totalSupply(votingToken.currentYear()), 2);
    }

    function testTotalSupplyAfterBurn() public {
        // 铸造token
        mockNFT.mint(user1, 1);
        vm.prank(user1);
        votingToken.mint();

        assertEq(votingToken.totalSupply(votingToken.currentYear()), 1);

        // 销毁token
        votingToken.burn(user1, votingToken.currentYear());

        // 验证总供应量减少
        assertEq(votingToken.totalSupply(votingToken.currentYear()), 0);
    }

    function testTotalSupplyDifferentYears() public {
        // Year 2026
        mockNFT.mint(user1, 1);
        vm.prank(user1);
        votingToken.mint();

        uint256 year2026 = votingToken.currentYear();
        assertEq(votingToken.totalSupply(year2026), 1);

        // 切换到 Year 2027
        votingToken.setCurrentYear(2027);

        // Year 2027的铸造
        mockNFT.mint(user2, 2);
        vm.prank(user2);
        votingToken.mint();

        // 验证不同year的供应量
        assertEq(votingToken.totalSupply(year2026), 1);
        assertEq(votingToken.totalSupply(votingToken.currentYear()), 1);
    }

    function testTotalSupplyNonExistentYear() public view {
        // 查询不存在的year的供应量
        uint256 nonExistentYear = votingToken.currentYear() + 1;
        assertEq(votingToken.totalSupply(nonExistentYear), 0);
    }

    function testTokenURI() public {
        // 测试当前season的URI (11)
        string memory expectedURI11 = "https://api.lxdao.io/buidler/badge/metadata/Governance_Rights_S11";
        assertEq(votingToken.uri(11), expectedURI11);

        // 测试下一个season的URI (12)
        string memory expectedURI12 = "https://api.lxdao.io/buidler/badge/metadata/Governance_Rights_S12";
        assertEq(votingToken.uri(12), expectedURI12);

        // 测试一个较大的数字
        string memory expectedURI999 = "https://api.lxdao.io/buidler/badge/metadata/Governance_Rights_S999";
        assertEq(votingToken.uri(999), expectedURI999);

        // 测试0
        string memory expectedURI0 = "https://api.lxdao.io/buidler/badge/metadata/Governance_Rights_S0";
        assertEq(votingToken.uri(0), expectedURI0);
    }

    function testAdminMint() public {
        // 测试管理员mint
        address recipient = makeAddr("recipient");
        uint256 year = 2027;

        // 确认初始状态
        assertEq(votingToken.balanceOf(recipient, year), 0);

        // 管理员mint
        votingToken.adminMint(recipient, year);

        // 验证mint结果
        assertEq(votingToken.balanceOf(recipient, year), 1);

        // 测试不能重复mint
        vm.expectRevert("Already minted for this year");
        votingToken.adminMint(recipient, year);

        // 测试不能mint到零地址
        vm.expectRevert("Cannot mint to zero address");
        votingToken.adminMint(address(0), year);
    }

    function testAdminMintBatch() public {
        // 准备测试数据
        address[] memory recipients = new address[](3);
        recipients[0] = makeAddr("recipient1");
        recipients[1] = makeAddr("recipient2");
        recipients[2] = makeAddr("recipient3");
        uint256 year = 2027;

        // 确认初始状态
        for (uint i = 0; i < recipients.length; i++) {
            assertEq(votingToken.balanceOf(recipients[i], year), 0);
        }

        // 管理员批量mint
        votingToken.adminMintBatch(recipients, year);

        // 验证mint结果
        for (uint i = 0; i < recipients.length; i++) {
            assertEq(votingToken.balanceOf(recipients[i], year), 1);
        }

        // 测试不能重复mint
        vm.expectRevert("Already minted for this year");
        votingToken.adminMintBatch(recipients, year);

        // 测试空地址列表
        address[] memory emptyList = new address[](0);
        vm.expectRevert("Empty address list");
        votingToken.adminMintBatch(emptyList, year);
    }

    function testAdminMintNotOwner() public {
        address recipient = makeAddr("recipient");
        uint256 year = 2027;

        // 非管理员尝试mint
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user1));
        votingToken.adminMint(recipient, year);
        vm.stopPrank();
    }
}
