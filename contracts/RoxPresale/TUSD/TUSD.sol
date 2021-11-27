// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./../ERC20.sol";


contract TUSD is ERC20 {
    constructor() ERC20("TUSD", "TUSD") {
        _mint(_msgSender(), 30_000_000 * (10**18));
    }
}
