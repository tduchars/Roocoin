//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

contract Context {
    constructor () public { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

 contract Owned {

address private owner;
address private newOwner;
 event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

/// @notice The Constructor assigns the message sender to be `owner`
constructor() public {
    owner = msg.sender;
}

modifier onlyOwner() {
    require(msg.sender == owner,"Owner only function");
    _;
}

/**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


contract ERC20 is Context, Owned, IERC20 {
    using SafeMath for uint;

    mapping (address => uint) internal _balances;

    mapping (address => mapping (address => uint)) internal _allowances;
    
    /*
    Address mappings to exclude from tax
    */
    
    mapping (address => bool) public TaxFreeWallets;
    event NewTaxFreeAddress(address sender, address newAddress);

    function setTaxFreeWallet(address _wallet) public onlyOwner{
        emit NewTaxFreeAddress(msg.sender, _wallet);
        TaxFreeWallets[_wallet] = true;
    }
    
    function containsTaxFree(address _wallet) public view returns (bool){
        return TaxFreeWallets[_wallet];
    }
    
    function removeTaxFreeWallet(address _wallet) public onlyOwner {
        delete TaxFreeWallets[_wallet];
    }
    
    /*
    Timelock: Allows you to lock a function for a specified period.
    */
    enum Functions { TAX }
    uint256 private constant _TIMELOCK = 259200; //3 days
    mapping(Functions => uint256) public timelock;
    
    modifier notLocked(Functions _fn) {
        require(timelock[_fn] != 0 && timelock[_fn] <= block.timestamp, "Function is timelocked");  
        _;
    }
    
    //unlock function
    function unlockFunction(Functions _fn) public onlyOwner {
        timelock[_fn] = block.timestamp + _TIMELOCK;
    }
    //lock function
    function lockFunction(Functions _fn) public onlyOwner {
        timelock[_fn] = 0;
    }

    uint internal _totalSupply;
    address public masterWallet = 0xd4F7a97Ad1E0Be2E65F391b8cDA54dd5e43B4902;
    uint public taxPercentageFirst = 1;
    
    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public override  returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view override returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal{
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint netAmount;
        
        if(containsTaxFree(sender)){
            netAmount = amount;
        } else {
            uint taxPercentage = findTaxPercentage(amount);
            netAmount = amount - taxPercentage;
            transferToMasterWallet(sender, masterWallet, taxPercentage);
        }
      
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(netAmount);
        emit Transfer(sender, recipient, netAmount);
    }
   
    function findTaxPercentage(uint256 _amount) internal view returns(uint256)
    {
         uint256 taxPercent = _amount * taxPercentageFirst / 100;
         return taxPercent;
    }
    function transferToMasterWallet(address sender, address _masterWallet, uint256 _taxPercentage) internal
    {
        _balances[_masterWallet] = _balances[_masterWallet].add(_taxPercentage);
        emit Transfer(sender, _masterWallet ,_taxPercentage);
        //_approve(sender, _masterWallet, _allowances[sender][_masterWallet].sub(_taxPercentage, "ERC20: transfer amount exceeds allowance"));
    }
 
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
  
    function _burn(address account, uint amount) public onlyOwner{
        require(account != address(0), "ERC20: burn from the zero address");
    
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function changeTaxPercentage(uint _taxPercentage) public onlyOwner {
        require(_taxPercentage <= 100, "Tax can not be charged more than 100%");
        taxPercentageFirst = _taxPercentage;
    }
    
    function changeMasterWalletAddress(address _masterWallet) public onlyOwner{
        require(_masterWallet != address(0), "Invalid address enetered");
        
        masterWallet = _masterWallet;
    }
}

contract ERC20Detailed is ERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}


/*
OpenZeppelin: checks address is actually an address
*/
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract RooCoin is ERC20, ERC20Detailed {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;
  
  constructor () public ERC20Detailed("RooCoin", "ROO", 18){
    _totalSupply =  400000000 *(10**uint256(18));
	_balances[msg.sender] = _totalSupply;
  }
  
}


