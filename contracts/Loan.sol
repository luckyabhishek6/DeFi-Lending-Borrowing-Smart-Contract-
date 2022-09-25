// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IERC20.sol";

contract Loan {
  using SafeMath for uint256;
  address public owner;
  uint256 public loanCount;
  uint256 public lendCount;
  uint256 public totalLiquidity;
  address public tokenAddress;
  uint256 public ethPerToken = 0.0001 ether; // 0.001 ether = 1 LUCKY

  struct LoanRequest {
    address borrower;
    uint256 loanAmount;
    uint256 collateralAmount;
    uint256 paybackAmount;
    uint256 loanDueDate;
    uint256 duration;
    uint256 loanId;
    bool isPayback;
  }

  struct LendRequest {
    address lender;
    uint256 lendId;
    uint256 lendAmountEther;
    uint256 lendAmountToken;
    uint256 paybackAmountEther;
    uint256 paybackAmountToken;
    uint256 timeLend;
    uint256 timeCanGetInterest; // lend more than 30 days can get interest
    bool retrieved;
    bool isLendEther;
  }

  mapping(address => uint256) public userLoansCount;
  mapping(address => uint256) public userLendsCount;
  mapping(address => mapping(uint256 => LoanRequest)) public loans;
  mapping(address => mapping(uint256 => LendRequest)) public lends;

  event NewLoanEther(
    address indexed borrower,
    uint256 loanAmount,
    uint256 collateralAmount,
    uint256 paybackAmount,
    uint256 loanDueDate,
    uint256 duration
  );

  event NewLend(
    address indexed lender,
    uint256 lendAmountEther,
    uint256 lendAmountToken,
    uint256 paybackAmountEther,
    uint256 paybackAmountToken,
    uint256 timeLend,
    uint256 timeCanGetInterest,
    bool retrieved,
    bool isLendEther
  );

  event Withdraw(
    bool isEarnInterest,
    bool isWithdrawEther,
    uint256 withdrawAmount
  );

  event PayBack(
    address borrower,
    bool paybackSuccess,
    uint256 paybackTime,
    uint256 paybackAmount,
    uint256 returnCollateralAmount
  );

  constructor(address _tokenAddress) {
    owner = msg.sender;
    loanCount = 1;
    lendCount = 1;
    totalLiquidity = 0;
    tokenAddress = _tokenAddress;
  }

  function init(uint256 _amount) public payable {
    require(totalLiquidity == 0);
    require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount),
      "Transaction failed on init function"
    );
    IERC20(tokenAddress).increaseAllowance(address(this), _amount);
    totalLiquidity = address(this).balance;
  }

  // calculate require colleteral token amount by passing ether amount
  function collateralAmount(uint256 _amount) public view returns (uint256) {
    // collateral amount = loan amount * 115%
    uint256 result = _amount.mul(115).div(100);
    result = result.div(ethPerToken);
    return result;
  }

  // calculate require ether amount by passing collateral amount
  function countEtherFromCollateral(uint256 _tokenAmount) public view returns (uint256) {
    // collateral amount / 115 % = loan amount
    uint256 result = (_tokenAmount.mul(ethPerToken)).div(115).mul(100);
    return result;
  }

  function checkEnoughLiquidity(uint256 _amount) public view returns (bool) {
    if(_amount > totalLiquidity) {
      return false;
    } else {
      return true;
    }
  }

  function loanEther(uint256 _amount, uint256 _duration) public {
    require(_amount >= ethPerToken, "loanEther: Not enough fund in order to loan");
    require(checkEnoughLiquidity(_amount), "loanEther: not enough liquidity");
    LoanRequest memory newLoan;
    newLoan.borrower = msg.sender;
    newLoan.loanAmount = _amount;
    newLoan.collateralAmount = collateralAmount(_amount) * (10 ** 18);
    newLoan.loanId = userLoansCount[msg.sender];
    newLoan.isPayback = false;
    if(_duration == 7) {
      // 6% interest
      newLoan.paybackAmount = _amount.mul(106).div(100);
      newLoan.loanDueDate = block.timestamp + 7 days;
      newLoan.duration = 7 days;
    } else if(_duration == 14) {
      // 7% interest
      newLoan.paybackAmount = _amount.mul(107).div(100);
      newLoan.loanDueDate = block.timestamp + 14 days;
      newLoan.duration = 14 days;
    } else if(_duration == 30) {
      // 8% interest
      newLoan.paybackAmount = _amount.mul(108).div(100);
      newLoan.loanDueDate = block.timestamp + 30 days;
      newLoan.duration = 30 days;
    } else {
      revert("loanEther: no valid duration!");
    }
    require(
      IERC20(tokenAddress).transferFrom(msg.sender, address(this), newLoan.collateralAmount),
      "loanEther: Transfer token from user to contract failed"
    );
    payable(msg.sender).transfer(_amount);
    IERC20(tokenAddress).increaseAllowance(address(this), newLoan.collateralAmount);
    loans[msg.sender][userLoansCount[msg.sender]] = newLoan;
    loanCount++;
    userLoansCount[msg.sender]++;
    totalLiquidity = totalLiquidity.sub(_amount);
    emit NewLoanEther(
      msg.sender,
      newLoan.loanAmount,
      newLoan.collateralAmount,
      newLoan.paybackAmount,
      newLoan.loanDueDate,
      newLoan.duration
    );
  }

  function lendEther() public payable {
    require(msg.value >= 0.0001 ether);
    LendRequest memory request;
    request.lender = msg.sender;
    request.lendId = userLendsCount[msg.sender];
    request.lendAmountEther = msg.value;
    request.lendAmountToken = 0;
    // 5% interest
    request.paybackAmountEther = msg.value.mul(105).div(100);
    request.paybackAmountToken = 0;
    request.timeLend = block.timestamp;
    request.timeCanGetInterest = block.timestamp + 30 days;
    request.retrieved = false;
    request.isLendEther = true;
    lends[msg.sender][userLendsCount[msg.sender]] = request;
    lendCount++;
    userLendsCount[msg.sender]++;
    totalLiquidity = totalLiquidity.add(msg.value);
    emit NewLend(
      request.lender,
      request.lendAmountEther,
      request.lendAmountToken,
      request.paybackAmountEther,
      request.paybackAmountToken,
      request.timeLend,
      request.timeCanGetInterest,
      request.retrieved,
      request.isLendEther
    );
  }

  function lendToken(uint256 _amount) public {
    require(IERC20(tokenAddress).transferFrom(
      msg.sender, address(this), _amount),
      "lendToken: Transfer token from user to contract failed"
    );
    LendRequest memory request;
    request.lender = msg.sender;
    request.lendId = userLendsCount[msg.sender];
    request.lendAmountEther = 0;
    request.lendAmountToken = _amount;
    // 5% interest
    request.paybackAmountEther = 0;
    request.paybackAmountToken = _amount.mul(105).div(100);
    request.timeLend = block.timestamp;
    request.timeCanGetInterest = block.timestamp + 30 days;
    request.retrieved = false;
    request.isLendEther = false;
    lends[msg.sender][userLendsCount[msg.sender]] = request;
    lendCount++;
    userLendsCount[msg.sender]++;
    IERC20(tokenAddress).increaseAllowance(address(this), request.paybackAmountToken);
    emit NewLend(
      request.lender,
      request.lendAmountEther,
      request.lendAmountToken,
      request.paybackAmountEther,
      request.paybackAmountToken,
      request.timeLend,
      request.timeCanGetInterest,
      request.retrieved,
      request.isLendEther
    );
  }

  function withdraw(uint256 _id) public {
    // LendRequest memory
    LendRequest storage req = lends[msg.sender][_id];
    require(req.lendId >= 0, "withdrawEther: Lend request not valid");
    require(req.retrieved == false, "withdrawEther: Lend request retrieved");
    require(req.lender == msg.sender, "withdrawEther: Only lender can withdraw");
    req.retrieved = true;
    if(block.timestamp > req.timeCanGetInterest) {
      // can get interest
      if(req.isLendEther) {
        // transfer ether to lender
        payable(req.lender).transfer(req.paybackAmountEther);
        emit Withdraw(
          true,
          true,
          req.paybackAmountEther
        );
      } else {
        // transfer token to lender
        IERC20(tokenAddress).transferFrom(address(this), req.lender, req.paybackAmountToken);
        emit Withdraw(
          true,
          false,
          req.paybackAmountToken
        );
      }
    } else {
      // transfer the original amount
      if(req.isLendEther) {
        // transfer ether to lender
        payable(req.lender).transfer(req.lendAmountEther);
        emit Withdraw(
          false,
          true,
          req.lendAmountEther
        );
      } else {
        // transfer token to lender
        IERC20(tokenAddress).transferFrom(address(this), req.lender, req.lendAmountToken);
        emit Withdraw(
          false,
          false,
          req.lendAmountToken
        );
      }
    }
  }

  function payback(uint256 _id) public payable {
    LoanRequest storage loanReq = loans[msg.sender][_id];
    require(loanReq.borrower == msg.sender, "payback: Only borrower can payback");
    require(!loanReq.isPayback, "payback: payback already");
    require(block.timestamp <= loanReq.loanDueDate, "payback: exceed due date");
    require(msg.value >= loanReq.paybackAmount, "payback: Not enough ether");
    require(
      IERC20(tokenAddress).transferFrom(address(this), msg.sender, loanReq.collateralAmount),
      "payback: Transfer collateral from contract to user failed"
    );
    loanReq.isPayback = true;
    emit PayBack(
      msg.sender,
      loanReq.isPayback,
      block.timestamp,
      loanReq.paybackAmount,
      loanReq.collateralAmount
    );
  }

  function getAllUserLoans()
    public
    view
    returns (LoanRequest[] memory)
  {
    LoanRequest[] memory requests = new LoanRequest[](userLoansCount[msg.sender]);
    for(uint256 i = 0; i < userLoansCount[msg.sender]; i++) {
      requests[i] = loans[msg.sender][i];
    }
    return requests;
  }

  function getUserOngoingLoans()
    public
    view
    returns (LoanRequest[] memory)
  {
    LoanRequest[] memory ongoing = new LoanRequest[](userLoansCount[msg.sender]);
    for(uint256 i = 0; i < userLoansCount[msg.sender]; i++) {
      LoanRequest memory req = loans[msg.sender][i];
      if(!req.isPayback && req.loanDueDate > block.timestamp) {
        ongoing[i] = req;
      }
    }
    return ongoing;
  }

  function getUserOverdueLoans()
    public
    view
    returns (LoanRequest[] memory)
  {
    LoanRequest[] memory overdue = new LoanRequest[](userLoansCount[msg.sender]);
    for(uint256 i = 0; i < userLoansCount[msg.sender]; i++) {
      LoanRequest memory req = loans[msg.sender][i];
      if(!req.isPayback && req.loanDueDate < block.timestamp) {
        overdue[i] = req;
      }
    }
    return overdue;
  }

  function getUserAllLends()
    public
    view
    returns (LendRequest[] memory)
  {
    LendRequest[] memory requests = new LendRequest[](userLendsCount[msg.sender]);
    for(uint256 i = 0; i < userLendsCount[msg.sender]; i++) {
      requests[i] = lends[msg.sender][i];
    }
    return requests;
  }

  function getUserNotRetrieveLend()
    public
    view
    returns (LendRequest[] memory)
  {
    LendRequest[] memory notRetrieved = new LendRequest[](userLendsCount[msg.sender]);
    for(uint256 i = 0; i < userLendsCount[msg.sender]; i++) {
      LendRequest memory req = lends[msg.sender][i];
      if(!req.retrieved) {
        notRetrieved[i] = req;
      }
    }
    return notRetrieved;
  }
}