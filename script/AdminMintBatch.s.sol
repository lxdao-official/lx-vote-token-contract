// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VotingPowerToken.sol";
import "forge-std/console.sol";

contract AdminMintBatch is Script {
    function run() external {
        // Load private key from environment variable
        string memory privateKeyStr = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(privateKeyStr);
        
        // Connect to the network
        string memory rpcUrl = vm.envString("RPC_URL");
        vm.createSelectFork(rpcUrl);

        // Contract address
        address contractAddress = 0x158C23A40208EefaEDbe9C80502B59e88755c9a5;
        VotingPowerToken token = VotingPowerToken(contractAddress);

        // Recipients addresses
        address[] memory recipients = new address[](10);
        recipients[0] = 0x99bbb439a42abb119015c6d3099C3355De0Def1B;
        recipients[1] = 0x233Ac30A896C5aBb30A21e98C755d8B0cd463DFB;
        recipients[2] = 0x902b13E46305E3AE10F70871C6D0bca9E5446b07;
        recipients[3] = 0x702566BED3CDf6804CB807f3489DFe567a6a1CBf;
        recipients[4] = 0x1138E94cfa05744C7c00AAf9FB86dF9D8b39Ef14;
        recipients[5] = 0xb15115A15d5992A756D003AE74C0b832918fAb75;
        recipients[6] = 0x0000049348454fb7B682260F72011087923f6Ed2;
        recipients[7] = 0x2E464dD8F27F1fCDDF67087983b712b4236Eb16b;
        recipients[8] = 0x016df27C5a9e479AB01e3053CD5a1967f96eCD6E;
        recipients[9] = 0x1d41D6B1091C1a8A334096771bd1776019243d5e;

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Current year is 2026
        uint256 year = 2026;

        // Batch mint tokens
        token.adminMintBatch(recipients, year);

        // Stop broadcasting
        vm.stopBroadcast();

        // Log success
        console.log("Successfully minted tokens for year", year);
        console.log("Number of recipients:", recipients.length);
    }
}
