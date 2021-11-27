// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./../ERC20.sol";


contract BSCUSD is ERC20 {
    constructor() ERC20("BSCUSD", "BSCUSD") {
        _mint(_msgSender(), 10_000_000 * (10**18));
    }
}
