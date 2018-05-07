pragma solidity ^0.4.21;
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import 'openzeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol';
import 'openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol';
import 'openzeppelin-solidity/contracts/crowdsale/distribution/FinalizableCrowdsale.sol';


contract TokenSale is Ownable, CappedCrowdsale, FinalizableCrowdsale {

  bool public initialized;
  uint[10] public rates;
  uint[10] public times;
  uint public noOfWaves;
  address public wallet;
  ERC20 public token;
  address public reserveWallet;
  uint public minContribution;
  uint public maxContribution;

  function TokenSale(uint _openingTime, uint _endTime, uint _hardCap, address _token, address _reserveWallet, uint _minContribution, uint _maxContribution)
  CappedCrowdsale(_hardCap) TimedCrowdsale(_openingTime, _endTime) {
    require(_token != address(0));
    require(_reserveWallet !=address(0));
    require(_maxContribution > 0);
    require(_minContribution > 0);
    reserveWallet = _reserveWallet;
    token = ERC20(_token);
    minContribution = _minContribution;
    maxContribution = _maxContribution;
  }

  function initRates(uint[] _rates, uint[] _times) public onlyOwner {
    require(now < openingTime);
    require(_rates.length == _times.length);
    require(_rates.length > 0);
    noOfWaves = _rates.length;

    for(uint8 i=0;i<_rates.length;i++) {
      rates[i] = _rates[i];
      times[i] = _times[i];
    }
  }

  function getCurrentRate() public view returns (uint256) {
    for(uint i=0;i<noOfWaves;i++) {
      if(now <= times[i]) {
        return rates[i];
      }
    }
    return 0;
  }

  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    uint rate  = getCurrentRate();
    return _weiAmount.mul(rate);
  }

  function setWallet(address _wallet) onlyOwner public {
    wallet = _wallet;
  }

  function setReserveWallet(address _reserve) onlyOwner public {
    require(_reserve != address(0));
    reserveWallet = _reserve;
  }

  function minContribution(uint _min) onlyOwner public {
    require(_min > 0);
    minContribution = _min;
  }

  function maxContribution(uint _max) onlyOwner public {
    require(_max > 0);
    maxContribution = _max;
  }

  function finalization() internal {
    wallet.transfer(this.balance);
    token.transfer(reserveWallet, token.balanceOf(this));
    super.finalization();
  }

  function _forwardFunds() internal {
    //overridden to make the smart contracts hold funds and not the wallet
  }

  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_weiAmount >= minContribution);
    require(_weiAmount <= maxContribution);
  }
}
