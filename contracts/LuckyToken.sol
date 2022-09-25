// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LuckyToken is ERC20 {
  constructor() ERC20("LUCKY TOKEN", "LUCKY") {
    _mint(msg.sender, 10000000000 * (10 ** 18));
  }

  function mint(uint256 _amount) public {
    _mint(msg.sender, _amount * (10 ** 18));
  }
}