// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

contract LiquityStabilityPoolMock  {

  constructor() public {
  }

  receive() external payable {}


  function _sendETHGainToDepositor(uint _amount) internal {
        if (_amount == 0) {return;}

        (bool success, ) = msg.sender.call{ value: _amount }("");
        require(success, "LiquityStabilityPoolMock: sending ETH failed");
    }

  function provideToSP(uint _amount, address _frontEndTag) external {}

  function withdrawFromSP(uint _amount) external {
    _sendETHGainToDepositor(address(this).balance);
  }
}