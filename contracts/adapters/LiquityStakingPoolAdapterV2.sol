// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {FixedPointMath} from "../libraries/FixedPointMath.sol";
import {IDetailedERC20} from "../interfaces/IDetailedERC20.sol";
import {IVaultAdapterV2} from "../interfaces/IVaultAdapterV2.sol";
import {ILiquityStakingPool} from "../interfaces/Liquity/ILiquityStakingPool.sol";
import {IUniswapV2Router02} from "../libraries/uni/IUniswapV2Router02.sol";

/// @title LiquityStakingPoolAdapterV2
///
/// @dev A vault adapter implementation which wraps a liquity vault.
contract LiquityStakingPoolAdapterV2 is IVaultAdapterV2 {
  using FixedPointMath for FixedPointMath.uq192x64;
  using SafeERC20 for IDetailedERC20;
  using SafeMath for uint256;

  /// @dev The vault that the adapter is wrapping.
  ILiquityStakingPool public vault;

  /// @dev UniswapV2Router
  IUniswapV2Router02 public uniV2Router;

  /// @dev lqtyToken
  IDetailedERC20 public lqtyToken;

  /// @dev wETH
  IDetailedERC20 public wETHToken;

  /// @dev lusd
  IDetailedERC20 public lusdToken;



  /// @dev The address which has admin control over this contract.
  address public admin;

  address public frontEndTag;

  /// @dev The decimals of the token.
  uint256 public decimals;

  constructor(ILiquityStakingPool _vault, address _admin, IUniswapV2Router02 _uniV2Router, IDetailedERC20 _lqtyToken, IDetailedERC20 _lusdToken, IDetailedERC20 _wethToken, address _frontendTag) public {
    vault = _vault;
    admin = _admin;
    uniV2Router = _uniV2Router;
    lqtyToken = _lqtyToken;
    lusdToken = _lusdToken;
    wETHToken = _wethToken;
    frontEndTag = _frontendTag;


    updateApproval();
    decimals = lusdToken.decimals();
  }

  receive() external payable {}

  /// @dev A modifier which reverts if the caller is not the admin.
  modifier onlyAdmin() {
    require(admin == msg.sender, "LiquityStakingPoolAdapterV2: only admin");
    _;
  }

  /// @dev Gets the token that the vault accepts.
  ///
  /// @return the accepted token.
  function token() external view override returns (IDetailedERC20) {
    return IDetailedERC20(address(lusdToken));
  }

  /// @dev Gets the total value of the assets that the adapter holds in the vault.
  ///
  /// @return the total assets.
  function totalValue() external view override returns (uint256) {
    (uint256 initialValue, address frontEndTag) = vault.deposits(address(this));
    return _sharesToTokens(initialValue);
  }

  /// @dev Deposits tokens into the vault.
  ///
  /// @param _amount the amount of tokens to deposit into the vault.
  function deposit(uint256 _amount) external override {
    vault.provideToSP(_amount,frontEndTag);
  }

  /// @dev Withdraws tokens from the vault to the recipient.
  ///
  /// This function reverts if the caller is not the admin.
  ///
  /// @param _recipient the account to withdraw the tokes to.
  /// @param _amount    the amount of tokens to withdraw.
  function withdraw(address _recipient, uint256 _amount, bool _isHarvest) external override onlyAdmin {
    // redeem lusd
    vault.withdrawFromSP(_tokensToShares(_amount));

    // sell lqty if is called from harvest
    if(_isHarvest){
      address[] memory _pathlqty = new address[](3);
      _pathlqty[0] = address(lqtyToken);
      _pathlqty[1] = address(wETHToken);
      _pathlqty[2] = address(lusdToken);

      address[] memory _pathEthLusd = new address[](2);
      _pathEthLusd[0] = address(wETHToken);
      _pathEthLusd[1] = address(lusdToken);


      if(lqtyToken.balanceOf(address(this)) > 0){
        uniV2Router.swapExactTokensForTokens(lqtyToken.balanceOf(address(this)),
                                             0,
                                             _pathlqty,
                                             address(this),
                                             block.timestamp+800);
      }


      if(address(this).balance > 0){
        uniV2Router.swapExactETHForTokens{value:address(this).balance}(0,
                                             _pathEthLusd,
                                             address(this),
                                             block.timestamp+800);
      }
    }

    // transfer all the dai in adapter to alchemist
    lusdToken.transfer(_recipient,lusdToken.balanceOf(address(this)));
  }

  /// @dev Updates the vaults approval of the token to be the maximum value.
  function updateApproval() public {
    IDetailedERC20(address(lusdToken)).safeApprove(address(vault), uint256(-1));
    lqtyToken.safeApprove(address(uniV2Router), uint256(-1));
  }

  /// @dev Computes the number of tokens an amount of shares is worth.
  ///
  /// @param _sharesAmount the amount of shares.
  ///
  /// @return the number of tokens the shares are worth.

  function _sharesToTokens(uint256 _sharesAmount) internal view returns (uint256) {
    return _sharesAmount;
  }

  /// @dev Computes the number of shares an amount of tokens is worth.
  ///
  /// @param _tokensAmount the amount of shares.
  ///
  /// @return the number of shares the tokens are worth.
  function _tokensToShares(uint256 _tokensAmount) internal view returns (uint256) {
    return _tokensAmount;
  }
}
