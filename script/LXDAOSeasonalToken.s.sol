// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/LXDAOSeasonalToken.sol";

contract DeployScript is Script {
    function run() external {
        // 获取部署者私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // 开始记录部署操作
        vm.startBroadcast(deployerPrivateKey);

        // 从环境变量获取 BuilderNFT 地址
        address builderNFTAddress = vm.envAddress("BUILDER_NFT_ADDRESS");
        
        // 部署 LXDAOSeasonalToken
        LXDAOSeasonalToken token = new LXDAOSeasonalToken(builderNFTAddress);

        // 停止记录
        vm.stopBroadcast();

        // 输出部署信息
        console.log("LXDAOSeasonalToken deployed at:", address(token));
    }
}
