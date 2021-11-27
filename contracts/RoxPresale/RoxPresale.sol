// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./AccessControlEnumerable.sol";
import "./SafeMath.sol";


abstract contract Globals {
    // testnet data
    address constant public BSC_USD_ADDRESS = 0x4a0Ce8465D187290e4f51Ced1e114F2B1d96b709;
    address constant public BUSD_ADDRESS = 0x483304c20C270e9ccED7A7C9d0daCaEFf842833A;
    address constant public TUSD_ADDRESS = 0x40B70563cC795941f478892fF475FcB358040e90;
    IERC20 constant public ROX_TOKEN = ERC20(0xa7BdA6Ee7DD9D26DF780470ec71B480BF70Fe10D);

    // production data
    //address constant public BSC_USD_ADDRESS = 0x55d398326f99059fF775485246999027B3197955;
    //address constant public BUSD_ADDRESS = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    //address constant public TUSD_ADDRESS = 0x14016E85a25aeb13065688cAFB43044C2ef86784;
    //IERC20 constant public ROX_TOKEN = ERC20(0xf921758DA283e166ED13312C0b92e21BDeFD82F2);
}


abstract contract Pauser is Context, AccessControlEnumerable, Pausable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Pauser: Must have pauser role to pause.");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Pauser: Must have pauser role to unpause.");
        _unpause();
    }
}


abstract contract VestingWallet is Globals, Pauser {
    uint256 internal _totalVestedAmount;

    mapping(address => uint256) internal _vestedAmountList;
    
    function totalVestedAmount() public view returns (uint256) {
        return _totalVestedAmount;
    }
    
    function vestedAmount(address _address) public view returns (uint256){
        return _vestedAmountList[_address];
    }

    function addVesting (address _address, uint256 amount) internal {
        _vestedAmountList[_address] += amount;
        _totalVestedAmount += amount;
        emit AddedVesting(_address, amount);
    }
    
    function releaseVesting(address _address) public {
        require(!paused(), "VestingWallet: contract is paused.");

        uint256 _vestedAmount = vestedAmount(_address);
        require(_vestedAmount > 0, "VestingWallet: No ROX tokens currently vested.");
        
        SafeERC20.safeTransfer(ROX_TOKEN, _address, _vestedAmount);
        _vestedAmountList[_address] = 0;
        _totalVestedAmount -= _vestedAmount;
        
        emit ReleasedVesting(_address);
    }

    event AddedVesting(address _address, uint256 amount);

    event ReleasedVesting(address _address);
}


abstract contract ReclaimContract is VestingWallet {
    function reclaimEther() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ReclaimContract: Must have admin role to call reclaimEther.");
        payable(_msgSender()).transfer(address(this).balance);
    }

    function reclaimToken(IERC20 _token) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ReclaimContract: Must have admin role to call reclaimToken.");
        uint256 balance = _token.balanceOf(address(this));
        SafeERC20.safeTransfer(_token, payable(_msgSender()), balance);
    }
}


contract RoxPresale is ReclaimContract {
    uint256 internal _presaleMinUSDAmount;
    uint256 internal _presalePriceInCents;
    uint256 internal _presaleInitAvailableTokens;
    uint256 internal _soldTokenAmount = 0;
    
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        
        _presalePriceInCents = SafeMath.mul(60, 1e18);
        _presaleInitAvailableTokens = SafeMath.mul(10_000_00, 1e18);
        _presaleMinUSDAmount = SafeMath.mul(10, 1e18);
    }

    function presaleMinUSDAmount() public view returns (uint256) {
        return _presaleMinUSDAmount;
    }
    
    function presalePriceInCents() public view returns (uint256) {
        return _presalePriceInCents;
    }
    
    function presaleInitAvailableTokens() public view returns (uint256) {
        return _presaleInitAvailableTokens;
    }
    
    function presaleAvailableTokens() public view returns (uint256) {
        return _presaleInitAvailableTokens - _soldTokenAmount;
    }
    
    function soldTokenAmount() public view returns (uint256) {
        return _soldTokenAmount;
    }
    
    
    function buyROX(IERC20 _fromToken, uint256 _fromAmount, address _toAddress) public payable {
        require(!paused(), "RoxPresale: contract is paused");
        require(_fromAmount > presaleMinUSDAmount(), "RoxPresale: Minimum amount of tokens not reached");

        address fromTokenAddress = address(_fromToken);
        require(fromTokenAddress == BSC_USD_ADDRESS || fromTokenAddress == BUSD_ADDRESS || fromTokenAddress == TUSD_ADDRESS, "RoxPresale: Only BSC-USD, BUSD, TUSD tokens. allowed") ;

        uint256 tokenAmount = SafeMath.div(SafeMath.mul(_fromAmount, 100), presalePriceInCents());
        require(tokenAmount >= presaleAvailableTokens(), "RoxPresale: Not enough ROX allocated for this phase");
        
        // transfer stable coins to the contract
        SafeERC20.safeTransferFrom(_fromToken, _msgSender(), address(this), _fromAmount);
        
        // add token to vesting wallet
        addVesting(_toAddress, tokenAmount);
        _soldTokenAmount += tokenAmount;
    }
}
