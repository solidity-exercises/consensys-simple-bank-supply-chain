pragma solidity ^0.4.13;
contract SimpleBank {

    event LogNewCustomer(address customer);
    event LogDepositMade(address indexed account, uint256 amount);
    event LogWithdrawal(address indexed account, uint256 amount, uint256 remainingBalance);

    mapping (address => uint256) public balances;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "The msg.sender must be the contract's owner!");
        _;
    }

    modifier isNewCustomer(address _customer) {
        require(balances[_customer] == 0, "The specified address must be a new customer!");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /// @notice Fallback function - Called if other functions don't match call
    /// or sent ether without data.
    /// Typically, called when invalid data is sent
    /// Added so ether sent to this contract is reverted if the contract fails
    /// otherwise, the sender's money is transferred to contract
    function() public payable {
        revert();
    }

    /// @notice Enroll a customer with the bank, giving them `_initialAmount` tokens for free
    /// @param _newCustomer - The address of the new customer.
    /// @param _initialAmount - Amount of tokens given for free when
    /// enrolling new customer.
    /// @dev Surplus one logic serves us as a boolean flag whether
    /// the customer is new.
    function enroll(address _newCustomer, uint256 _initialAmount) public onlyOwner isNewCustomer(_newCustomer) {
        emit LogNewCustomer(_newCustomer);

        balances[_newCustomer] = _initialAmount + 1;
    }

    /// @notice Deposit ether into bank
    function deposit() public payable {
        require(msg.value > 0, "Zero value deposits are forbidden!");

        emit LogDepositMade(msg.sender, msg.value);

        uint256 oldBalance = balances[msg.sender];

        balances[msg.sender] += msg.value;

        assert(balances[msg.sender] > oldBalance);
    }

    /// @notice Withdraw ether from bank
    /// @param _withdrawAmount - Amount you want to withdraw.
    function withdraw(uint256 _withdrawAmount) public {
        require(balances[msg.sender] > _withdrawAmount, "You do not have enough balance!");
        
        uint256 remainingBalance = balances[msg.sender] - _withdrawAmount - 1;
        emit LogWithdrawal(msg.sender, _withdrawAmount, remainingBalance);

        balances[msg.sender] -= _withdrawAmount;
        
        msg.sender.transfer(_withdrawAmount);
    }
}
