pragma solidity ^0.6.12;



interface ILiquityStakingPool{
  function provideToSP(uint _amount, address _frontEndTag) external;
  function withdrawFromSP(uint _amount) external;
  function deposits(address _user) external view returns (uint initialValue, address frontEndTag);

}
