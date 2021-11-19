// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";


abstract contract LockedList is ERC20PresetMinterPauser {
    mapping (address => bool) public isLockedList;

    function isLocked(address _address) public returns (bool){
        return isLockedList[_address];
    }

    function addLock (address _address) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LockedList: must have admin role to add lock");
        isLockedList[_address] = true;
        AddedLocked(_address);
    }

    function removeLock (address _address) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LockedList: must have admin role remove lock");
        isLockedList[_address] = false;
        RemovedLocked(_address);
    }

    function destroyLockedFunds (address _address) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LockedList: must have admin role to detroy locked funds");
        require(isLockedList[_address], "LockedList: address is not locked");

        uint funds = balanceOf(_address);

        this._balances[_address] = 0;
        this._totalSupply -= funds;
        DestroyedLockedFunds(_address, funds);
    }

    event AddedLocked(address _address);

    event RemovedLocked(address _address);

    event DestroyedLockedFunds(address _address, uint _balance);
}


abstract contract FeeToken is LockedList {
    mapping(address => bool) public isFeeFree;

    function addFeeFree(address _address) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LockedList: must have admin role to add fee free address");
        isFeeFree[_address] = true;
    }

    function removeFeeFree(address _address) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LockedList: must have admin role to remove fee free address");
        isFeeFree[_address] = false;
    }

    function _transfer(address sender,  address recipient, uint256 amount) internal virtual override {
        require(sender != address(0), "FeeToken: transfer from the zero address");
        require(recipient != address(0), "FeeToken: transfer to the zero address");

        uint256 txFee = 0;
        if (isFeeFree(sender)){
            txFee = amount / 100; //1% transfer fee
        }

        uint256 totalAmount = amount + txFee;

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = this._balances[sender];
        require(senderBalance >= totalAmount, "FeeToken: transfer amount exceeds balance with 1% fee.");

        _burn(sender, txFee);

        unchecked {
            super._balances[sender] = senderBalance - totalAmount;
        }
        super._balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }
}


contract RoxToken is FeeToken {
    uint256 private constant INITIAL_SUPPLY = 70_000_000 * (10**18);

    constructor() ERC20PresetMinterPauser("ROX", "ROX") {
        _mint(_msgSender(), INITIAL_SUPPLY);
    }
}
