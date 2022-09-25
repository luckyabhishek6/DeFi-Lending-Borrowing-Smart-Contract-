require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config({path:'./.env.local'});

task("accounts", "Prints the list of accounts", async(taskArgs, hre) => {
    const accounts = await hre.ethers.getSigners();

    for (const account of accounts) {
        console.log(account.address);
    }
});
const privateKey= process.env.NEXT_PUBLIC_PRIVATE_KEY
module.exports = {
    solidity: "0.8.4",
    networks: {
        ropsten: {
            url:process.env.NEXT_PUBLIC_RPC_URL,
            accounts: [privateKey],
        },
    },
    etherscan: {
        apiKey: "YWN2M9EMSYSQKIHNC1NBAK39KF53GHRN77",
    },
};