- complete project-->https://github.com/luckyabhishek6/DiFi-LendingDapp.git
# A Lending and borrowing decentralised application Smart contract deployed on Ropsten test network 

Successfully verified contract Loan on Etherscan.
https://ropsten.etherscan.io/address/0x682438317a94cE9bB31915Bda482bb2F5001545F#code 

Warning! Ropsten network and this faucet will be shut down in Oct 2022.
More info in  Ethereum Foundation blog(https://blog.ethereum.org/2022/09/09/kiln-shutdown).

firsly install hardhat usnig
```
npm install --save-dev hardhat
```
 
compile your smart contract using
```
npx hardhat compile
```
# hardhat configuration

The project folder will contain a `hardhat.config.js` file which is the configuration file, located at the root of the project directory.

```
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
        goerli: {
            url:process.env.NEXT_PUBLIC_RPC_URL,
            accounts: [privateKey],
        },
    },
    etherscan: {
        apiKey: "YWN2M9EMSYSQKIHNC1NBAK39KF53GHRN**",
    },
};

```

The project folder will contain a `deploy.js` file which is the configuration file, located at the script folder of the project directory.
```
const hre = require("hardhat");
// token: 0x09767b590F2961cA5B05ADc588A8e203274bF08f
// loan:  0x682438317a94cE9bB31915Bda482bb2F5001545F
// npx hardhat verify --network ropston 0x682438317a94cE9bB31915Bda482bb2F5001545F "0x09767b590F2961cA5B05ADc588A8e203274bF08f"


/*Successfully verified contract Loan on Etherscan.
https://ropsten.etherscan.io/address/0x682438317a94cE9bB31915Bda482bb2F5001545F#code
*/

async function main() {
    // const LuckyToken = await hre.ethers.getContractFactory("LuckyToken");
    const Loan = await hre.ethers.getContractFactory("Loan");
    // const luckyToken = await LuckyToken.deploy();
    // await luckyToken.deployed();
    const loan = await Loan.deploy("0x09767b590F2961cA5B05ADc588A8e203274bF08f");
    await loan.deployed();

    // console.log("LuckyToken deployed to:", luckyToken.address);
    console.log("Loan deployed to:", loan.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
    
```
and deploy  smart contract using 
```
npx hardhat run --network <network> scripts/deploy.js
```

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```
