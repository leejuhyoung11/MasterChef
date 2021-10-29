// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol";

contract CakeToken is BEP20('PancakeSwap Token', 'Cake') {
    
    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

}