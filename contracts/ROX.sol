// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";


abstract contract LockedList is ERC20PresetMinterPauser {
    mapping (address => bool) public isLockedList;

    function isLocked(address _address) public view returns (bool){
        return isLockedList[_address];
    }

    function addLock (address _address) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LockedList: must have admin role to add lock");
        isLockedList[_address] = true;
        emit AddedLocked(_address);
    }

    function removeLock (address _address) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LockedList: must have admin role remove lock");
        isLockedList[_address] = false;
        emit RemovedLocked(_address);
    }

    event AddedLocked(address _address);

    event RemovedLocked(address _address);
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
        require(!isLocked(sender), "FeeToken: Sender is locked");
        require(!isLocked(recipient), "FeeToken: Recipient is locked");
        
        if (isFeeFree[sender] != true){
            _burn(sender, amount / 100); //1% transfer fee
        }
        
        super._transfer(sender, recipient, amount);
    }
}


contract RoxToken is FeeToken {
    uint256 private constant INITIAL_SUPPLY = 70_000_000 * (10**18);

    constructor() ERC20PresetMinterPauser("ROX", "ROX") {
        _mint(_msgSender(), INITIAL_SUPPLY);
    }
}
