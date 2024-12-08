// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VotingPowerToken.sol";
import "forge-std/console.sol";

contract DeployVotingPowerToken is Script {
    function run() external {
        // Load .env file
        string memory root = vm.projectRoot();
        console.log("Project root:", root);
        console.log("Loading .env from:", string.concat(root, "/.env"));

        // Get deployer private key from environment variable
        string memory privateKeyStr = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(privateKeyStr);

        string memory rpcUrl = vm.envString("RPC_URL");
        vm.createSelectFork(rpcUrl);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Get BuilderNFT address from environment variable
        address builderNFTAddress = vm.envAddress("BUILDER_NFT_ADDRESS");
        console.log("BuilderNFTAddress:", builderNFTAddress);
        // Deploy VotingPowerToken
        VotingPowerToken token = new VotingPowerToken(builderNFTAddress);

        // Stop broadcasting
        vm.stopBroadcast();

        // Log the deployment address
        console.log("VotingPowerToken deployed at:", address(token));
    }
}
