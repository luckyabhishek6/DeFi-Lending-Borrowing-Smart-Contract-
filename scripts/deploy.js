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