const BigNumber = web3.BigNumber;
const { expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const TestERC20 = artifacts.require('TestERC20');
const Marketplace = artifacts.require('MarketPlace');

contract('Marketplace', ([account1, account2, account3]) => {
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

  it('should mint NFT', async () => {
    const collection = await marketplace._collections(0);
    expectEvent(
      await marketplace.mintNFT(collection, 'NO_URI', account1, { value: web3.utils.toWei('0.0005'), from: account2 }),
      'Mint'
    );
  });

  it('should place an item for sale', async () => {
    const collection = await marketplace._collections(0);
    const encodedCall = web3.eth.abi.encodeFunctionCall(
      {
        name: 'approve',
        type: 'function',
        inputs: [
          {
            type: 'address',
            name: 'to',
          },
          {
            type: 'uint256',
            name: 'tokenId',
          },
        ],
      },
      [marketplace.address, 1]
    );

    await web3.eth.sendTransaction({
      from: account1,
      to: collection,
      value: web3.utils.toWei('0'),
      data: encodedCall,
    });

    expectEvent(
      await marketplace.placeForSale(
        1,
        collection,
        account1,
        '0x0000000000000000000000000000000000000000',
        web3.utils.toWei('0.003')
      ),
      'MarketItemCreated'
    );
  });

  it('should destroy an NFT', async () => {
    const collection = await marketplace._collections(0);
    expectEvent(await marketplace.destroyNFT(collection, 1), 'Burn');
  });
});
