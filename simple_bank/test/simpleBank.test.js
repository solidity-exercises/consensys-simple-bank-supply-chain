const SimpleBank = artifacts.require("../contracts/SimpleBank.sol");

contract('SimpleBank', ([owner, alice, bob]) => {
  let bank;
  const initialAmount = 1000;
  const deposit = web3.toBigNumber(2);

  beforeEach(async () => {
    bank = await SimpleBank.new();
    await bank.enroll(alice, initialAmount, { from: owner });
    await bank.enroll(bob, initialAmount, { from: owner });
  });

  it("should put 1000 tokens in the first and second account", async () => {
    const aliceBalance = await bank.balances.call(alice);
    assert.equal(aliceBalance, 1001, 'enroll balance is incorrect, check balance method or constructor');

    const bobBalance = await bank.balances.call(bob);
    assert.equal(bobBalance, 1001, 'enroll balance is incorrect, check balance method or constructor');

    const ownerBalance = await bank.balances.call(owner);
    assert.equal(ownerBalance, 0, 'only enrolled users should have balance, check balance method or constructor')
  });

  it("should deposit correct amount", async () => {
    const { logs } = await bank.deposit({ from: alice, value: deposit });
    const aliceBalance = await bank.balances.call(alice);
    assert.equal(deposit.plus(1001).toString(), aliceBalance, 'deposit amount incorrect, check deposit method');

    const expectedEventResult = { account: alice, amount: deposit };

    assert.equal(logs[0].event, 'LogDepositMade')

    const logAccountAddress = logs[0].args.account;
    const logAmount = logs[0].args.amount.toNumber();

    assert.equal(expectedEventResult.account, logAccountAddress, "LogDepositMade event account property not emitted, check deposit method");
    assert.equal(expectedEventResult.amount, logAmount, "LogDepositMade event amount property not emitted, check deposit method");
  });

  it("should withdraw correct amount", async () => {
    await bank.deposit({ from: alice, value: deposit });
    await bank.withdraw(deposit, { from: alice });

    const aliceBalance = await bank.balances.call(alice);

    assert.equal(initialAmount + 1, aliceBalance.valueOf(), 'withdraw amount incorrect, check withdraw method');
  });

});
