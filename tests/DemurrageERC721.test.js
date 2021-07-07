// @ts-check
const DemurrageERC721 = artifacts.require('DemurrageERC721');
const MockToken = artifacts.require('MockToken');

const increaseTime = require('./utils/increaseTime.js').increaseTime;
const assertRevert = require('./utils/assertRevert.js').assertRevert;
const latestTime = async () => {
	return (await web3.eth.getBlock('latest')).timestamp;
};

// THESE ARE VERY BASIC TESTS
contract('DemurrageERC721.sol', ([user1, user2, user3]) => {
	it('Complete testing', async () => {
		const mToken = await MockToken.new();
		await mToken.transfer(user2, String(10 * 1e18), { from: user1 });
		const dToken = await DemurrageERC721.new(user1, mToken.address);
		await dToken.mint(user2, String(1e18));
		let paidTill = (await dToken.demurrageTokens(1)).paidTill / 1;
		console.log('🚀 ~ file: DemurrageERC721.test.js ~ line 17 ~ it ~ paidTill', paidTill);
		await increaseTime(100);
		await assertRevert(dToken.transferFrom(user2, user3, 1, { from: user2 }));
		await assertRevert(dToken.payDemurrage(1, String(paidTill + 86400)));
		await assertRevert(dToken.payDemurrage(1, String(paidTill + 86400), { from: user2 }));
		mToken.approve(dToken.address, String(10e18), { from: user2 });
		await assertRevert(dToken.payDemurrage(1, String(paidTill + 86400 - 1), { from: user2 }));
		await dToken.payDemurrage(1, String(paidTill + 86400), { from: user2 });
		let paidTill2 = (await dToken.demurrageTokens(1)).paidTill / 1;
		console.log('🚀 ~ file: DemurrageERC721.test.js ~ line 27 ~ it ~ paidTill2', paidTill2);
		assert.equal(paidTill + 86400, paidTill2);
		await dToken.transferFrom(user2, user3, 1, { from: user2 });
		await dToken.mint(user2, String(1e3));
		paidTill = (await dToken.demurrageTokens(2)).paidTill / 1;
		await dToken.payDemurrage(2, String(paidTill + 86400), { from: user2 });
		await dToken.payDemurrage(2, String(paidTill + 86400), { from: user2 });

		console.log(await dToken.events.allEvents({ fromBlock: 0, toBlock: 'latest' }));
	});
});
