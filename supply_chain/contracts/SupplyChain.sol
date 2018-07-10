pragma solidity ^0.4.23;


contract SupplyChain {

  event LogForSale(string indexed sku, string skuAsString);
  event LogSold(string indexed sku, string skuAsString);
  event LogShipped(string indexed sku, string skuAsString);
  event LogReceived(string indexed sku, string skuAsString);
  event LogWithdrawal(address indexed receiver, uint256 amount);

  enum State { ForSale, Sold, Shipped, Received }

  struct Item {
    uint256 price;
    bytes23 name;
    State state;
    address seller;
    address buyer;
  }

  mapping (bytes32=>Item) public items;
  mapping (address=>uint256) public balanceOf;

  modifier verifyCaller (address _address) { 
    require (msg.sender == _address); 
    _;
  }

  modifier checkValue(string _sku) {
    bytes32 sku = keccak256(abi.encodePacked(_sku));
    uint256 price = items[sku].price;
    require(msg.value >= price, "The value sent is not sufficient to buy the item!"); 

    _;
    
    if (msg.value > price) {
      uint256 amountToRefund = msg.value - price;

      address buyer = items[sku].buyer;

      uint256 buyerOldBalance = balanceOf[buyer];
      balanceOf[buyer] += amountToRefund;

      assert(balanceOf[buyer] > buyerOldBalance);
    }
  }

  modifier forSale(string _sku) {
    bytes32 sku = keccak256(abi.encodePacked(_sku));
    State state = items[sku].state;
    require(state == State.ForSale, "The item's state must be ForSale!");
    _;
  }

  modifier sold(string _sku) {
    bytes32 sku = keccak256(abi.encodePacked(_sku));
    State state = items[sku].state;
    require(state == State.Sold, "The item's state must be Sold!");
    _;
  }

  modifier shipped(string _sku) {
    bytes32 sku = keccak256(abi.encodePacked(_sku));
    State state = items[sku].state;
    require(state == State.Shipped, "The item's state must be Shipped!");
    _;
  }

  modifier received(string _sku) {
    bytes32 sku = keccak256(abi.encodePacked(_sku));
    State state = items[sku].state;
    require(state == State.Received, "The item's state must be Received!");
    _;
  }

  modifier checkWithdrawal(uint256 _value) {
    require(_value > 0, "Zero value transfers are not allowed!");
    require(balanceOf[msg.sender] >= _value, "You do not have enough balanceOf!");
    _;
  }

  function () public payable {
    revert("Wrong invocation reverted from the fallback!");
  }

  function addItem(string _sku, bytes23 _name, uint256 _price) public {
    emit LogForSale(_sku, _sku);

    bytes32 sku = keccak256(abi.encodePacked(_sku));

    items[sku] = Item({price: _price, name: _name, state: State.ForSale, seller: msg.sender, buyer: address(0)});
  }

  function buyItem(string _sku)
    public
    payable
    forSale(_sku)
    checkValue(_sku)
  {
    emit LogSold(_sku, _sku);

    bytes32 sku = keccak256(abi.encodePacked(_sku));

    items[sku].state = State.Sold;

    uint256 price = items[sku].price;

    if (price > 0) {
      address seller = items[sku].seller;

      uint256 sellerOldBalance = balanceOf[seller];
      balanceOf[seller] += price;

      assert(balanceOf[seller] > sellerOldBalance);
    }
  }

  function shipItem(string _sku)
    public
    sold(_sku)
    verifyCaller(items[keccak256(abi.encodePacked(_sku))].seller)
  {
    emit LogShipped(_sku, _sku);

    bytes32 sku = keccak256(abi.encodePacked(_sku));

    items[sku].state = State.Shipped;
  }

  function receiveItem(string _sku)
    public
    shipped(_sku)
    verifyCaller(items[keccak256(abi.encodePacked(_sku))].buyer)
  {
    emit LogReceived(_sku, _sku);

    bytes32 sku = keccak256(abi.encodePacked(_sku));

    items[sku].state = State.Received;
  }

  function withdraw(uint256 _value) public checkWithdrawal(_value) {
    emit LogWithdrawal(msg.sender, _value);

    balanceOf[msg.sender] -= _value;

    msg.sender.transfer(_value);
  }
}
