// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol";
import "./CakeToken.sol";


contract SyrupBar is BEP20('SyrupBar Token', 'SYRUP') {
    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    CakeToken public cake;

    constructor(CakeToken _cake) public{
        cake = _cake;
    }

    function safeCakeTransfer(address _to , uint256 _amount) public {
        uint256 cakeBal = cake.balanceOf(address(this));
        if(_amount > cakeBal) {cake.transfer(_to, cakeBal);}
        else {cake.transfer(_to, _amount);}
    }

}