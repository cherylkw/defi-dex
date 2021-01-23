pragma solidity 0.6.3;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract Rep is ERC20 {
  constructor() ERC20('Augur token', 'REP') public {}

  function faucet(address to, uint amount) external {
    _mint(to, amount);
  }
}