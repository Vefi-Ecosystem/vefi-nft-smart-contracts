const BigNumber = web3.BigNumber;
const { expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const TestERC20 = artifacts.require('TestERC20');
const Marketplace = artifacts.require('MarketPlace');

contract('Marketplace', ([account1, account2]) => {
  let marketplace;
  let utilityToken;

  before(async () => {
    utilityToken = await TestERC20.new(web3.utils.toWei('1000000000000'));
    marketplace = await Marketplace.new(
      utilityToken.address,
      web3.utils.toWei('30000'),
      web3.utils.toWei('0.0005'),
      10,
      4,
      web3.utils.toWei('0.005'),
      account2
    );
  });

  it('should deploy collection', async () => {
    await marketplace.deployCollection('COLLECTION 1', 'C1', 'GENERAL', account2, 'NO_URI', {
      value: web3.utils.toWei('0.005'),
    });
    const collection = await marketplace._collections(0);
    const callValue1 = await web3.eth.call({ to: collection, data: web3.utils.sha3('name()') });
    const callValue2 = await web3.eth.call({ to: collection, data: web3.utils.sha3('_imageURI()') });
    assert.equal(web3.eth.abi.decodeParameters(['string'], callValue1)[0], 'COLLECTION 1');
    assert.equal(web3.eth.abi.decodeParameters(['string'], callValue2)[0], 'NO_URI');
  });
});
