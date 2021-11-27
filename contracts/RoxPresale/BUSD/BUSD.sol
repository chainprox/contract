// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./../ERC20.sol";


contract BUSD is ERC20 {
    constructor() ERC20("BUSD", "BUSD") {
        _mint(_msgSender(), 20_000_000 * (10**18));
    }
}
