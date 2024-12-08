// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract LXDAOSeasonalToken is ERC20, Ownable {
    IERC721 public builderNFT;
    uint256 public constant CLAIM_AMOUNT = 1; // 每次claim 1个代币
    uint256 public lastBurnTimestamp;

    mapping(address => uint256) public lastClaimTimestamp;

    event TokensClaimed(address indexed user, uint256 amount);
    event TokensBurned(uint256 amount);

    // 添加状态变量
    address[] public tokenHolders;
    mapping(address => bool) public isTokenHolder;

    constructor(
        address _builderNFTAddress
    ) ERC20("LXDAO Seasonal Token", "LXST") Ownable(msg.sender) {
        builderNFT = IERC721(_builderNFTAddress);
        lastBurnTimestamp = block.timestamp;
    }

    function claim() external {
        require(isBuilder(msg.sender), "Must be a Builder NFT holder");
        require(canClaim(msg.sender), "Already claimed this period");

        lastClaimTimestamp[msg.sender] = block.timestamp;
        _mint(msg.sender, CLAIM_AMOUNT);

        emit TokensClaimed(msg.sender, CLAIM_AMOUNT);
    }

    function burnToken(uint256 amount, address target) external {
        address burnAddress = (msg.sender == owner()) ? target : msg.sender;
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(burnAddress) >= amount, "Insufficient balance");

        _burn(burnAddress, amount);
        emit TokensBurned(amount);
    }

    function burnAllTokens() external onlyOwner {
        uint256 totalSupply = totalSupply();
        require(totalSupply > 0, "No tokens to burn");

        // 更新最后销毁时间戳
        lastBurnTimestamp = block.timestamp;

        // 销毁所有持有者的代币
        while (tokenHolders.length > 0) {
            address holder = tokenHolders[tokenHolders.length - 1];
            uint256 balance = balanceOf(holder);
            if (balance > 0) {
                _burn(holder, balance);
            }
            // removeHolder 会在 _beforeTokenTransfer 中被调用
        }

        emit TokensBurned(totalSupply);
    }

    function isBuilder(address _user) public view returns (bool) {
        return builderNFT.balanceOf(_user) > 0;
    }

    function canClaim(address _user) public view returns (bool) {
        return !isTokenHolder[_user];
    }

    // 修改 _beforeTokenTransfer 来跟踪持有者
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // 只允许铸造（from == address(0)）和销毁（to == address(0)）操作
        require(
            from == address(0) || to == address(0),
            "Token transfers are not allowed"
        );

        // 调用父合约实现来处理铸造和销毁
        super._update(from, to, amount);

        // 处理代币持有者追踪逻辑（仅在铸造时）
        if (to != address(0)) {
            require(isBuilder(to), "Recipient must be a Builder NFT holder");
            if (!isTokenHolder[to]) {
                tokenHolders.push(to);
                isTokenHolder[to] = true;
            }
        }

        // 在销毁时移除持有者
        if (from != address(0) && balanceOf(from) == 0) {
            removeHolder(from);
        }
    }

    // 添加移除持有者的辅助函数
    function removeHolder(address holder) internal {
        if (!isTokenHolder[holder]) return;

        for (uint256 i = 0; i < tokenHolders.length; i++) {
            if (tokenHolders[i] == holder) {
                tokenHolders[i] = tokenHolders[tokenHolders.length - 1];
                tokenHolders.pop();
                isTokenHolder[holder] = false;
                break;
            }
        }
    }

    function decimals() public pure virtual override returns (uint8) {
        return 0;
    }
}
