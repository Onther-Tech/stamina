pragma solidity ^0.4.24;

contract Stamina {
  /**
   * Internal States
   */
  // delegatee of `from` account
  // `from` => `delegatee`
  mapping (address => address) public _delegatee;

  // Stamina balance of delegatee
  // `delegatee` => `balance`
  mapping (address => uint) public _balance;

  // total deposit of delegatee
  // `delegatee` => `total deposit`
  mapping (address => uint) public _total_deposit;

  // deposit of delegatee
  // `depositor` => `delegatee` => `deposit`
  mapping (address => mapping (address => uint)) public _deposit;

  uint public t = 0xdead;

  bool public initialized;

  /**
   * Public States
   */
  uint public MIN_DEPOSIT;

  /**
   * Modifiers
   */
  modifier onlyChain() {
    // TODO: uncomment below
    // require(msg.sender == address(0));
    _;
  }

  /**
   * Events
   */
  event Deposited(address indexed depositor, address indexed delegatee, uint amount);
  event Withdrawal(address indexed depositor, address indexed delegatee, uint amount);
  event DelegateeChanged(address from, address oldDelegatee, address newDelegatee);

  /**
   * Init
   */
  function init(uint minDeposit) external {
    require(!initialized);

    MIN_DEPOSIT = minDeposit;

    initialized = true;
  }

  /**
   * Getters
   */
  function getDelegatee(address from) public view returns (address) {
    return _delegatee[from];
  }

  function getBalance(address addr) public view returns (uint) {
    return _balance[addr];
  }

  function getTotalDeposit(address delegatee) public view returns (uint) {
    return _total_deposit[delegatee];
  }

  function getDeposit(address depositor, address delegatee) public view returns (uint) {
    return _deposit[depositor][delegatee];
  }

  /**
   * Setters and External functions
   */
  /// @notice change current delegatee
  function setDelegatee(address newDelegatee) external returns (bool) {
    address oldDelegatee = _delegatee[msg.sender];

    _delegatee[msg.sender] = newDelegatee;

    emit DelegateeChanged(msg.sender, oldDelegatee, newDelegatee);
    return true;
  }

  /// @notice deposit Ether to delegatee
  function deposit(address delegatee) external payable returns (bool) {
    require(msg.value >= MIN_DEPOSIT);

    uint dTotalDeposit = _total_deposit[delegatee];
    uint fDeposit = _deposit[msg.sender][delegatee];

    require(dTotalDeposit + msg.value > dTotalDeposit);
    require(fDeposit + msg.value > fDeposit);

    _total_deposit[delegatee] = dTotalDeposit + msg.value;
    _deposit[msg.sender][delegatee] = fDeposit + msg.value;

    emit Deposited(msg.sender, delegatee, msg.value);
    return true;
  }

  /// @notice request to withdraw Ether from delegatee. it store Ether to Escrow contract.
  ///         later `withdrawPayments` transfers Ether from Escrow to the depositor
  function withdraw(address delegatee, uint amount) external returns (bool) {
    uint dTotalDeposit = _total_deposit[delegatee];
    uint fDeposit = _deposit[msg.sender][delegatee];

    require(dTotalDeposit - amount < dTotalDeposit);
    require(fDeposit - amount < fDeposit);

    _total_deposit[delegatee] = dTotalDeposit - amount;
    _deposit[msg.sender][delegatee] = fDeposit - amount;

    msg.sender.transfer(amount);

    emit Withdrawal(msg.sender, delegatee, amount);
    return true;
  }

  /// @notice reset stamina up to total deposit of delegatee
  function resetStamina(address delegatee) external onlyChain {
    _balance[delegatee] = _total_deposit[delegatee];
  }

  /// @notice add stamina of delegatee. The upper bound of stamina is total deposit of delegatee.
  function addStamina(address delegatee, uint amount) external onlyChain returns (bool) {
    uint dTotalDeposit = _total_deposit[delegatee];
    uint dBalance = _balance[delegatee];

    require(dBalance + amount > dBalance);
    uint targetBalance = dBalance + amount;

    if (targetBalance > dTotalDeposit) _balance[delegatee] = dTotalDeposit;
    else _balance[delegatee] = targetBalance;

    return true;
  }

  /// @notice subtracte stamina of delegatee.
  function subtractStamina(address delegatee, uint amount) external onlyChain returns (bool) {
    uint dBalance = _balance[delegatee];

    require(dBalance - amount < dBalance);
    _balance[delegatee] = dBalance - amount;
    return true;
  }
}
