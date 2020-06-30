var AuctionRepository = artifacts.require("./AuctionRepository.sol");
var DeedRepository = artifacts.require("./DeedRepository.sol");
const fs = require("fs");

contract("AuctionRepository", async (accounts) => {
	let auctionInstance, deedInstance, ownerOfDeed;

	before("setup contract for each test", async function () {
		auctionInstance = await AuctionRepository.deployed();
		deedInstance = await DeedRepository.deployed();
		// register deed
		await deedInstance.registerDeed(123456789, "Katie:123456789");
	});

	it("It should check if the auction repository is initialized", async () => {
		let auctionLength = await auctionInstance.getCount();
		assert.equal(auctionLength.valueOf(), 0, `${auctionLength} auctions instead of 0`);
	});

	it(`It should create an auction under ${accounts[0]} account`, async () => {
		const deedAddress = deedInstance.address;
		await auctionInstance.createAuction(deedAddress, 123456789, "KATE", "meta://katie", 10, Math.floor(new Date().getTime() / 1000) + 60);
		let auctionCount = await auctionInstance.getAuctionsCountOfOwner(accounts[0]);
		assert.equal(auctionCount.valueOf(), 1, `auctions of ${deedAddress} should be 1`);
	});

	it.skip(`It should bid on the last auction`, async () => {
		await auctionInstance.bidOnAuction(0);
		let bidsCount = await auctionInstance.getBidsCount(0);
		assert.equal(bidsCount.valueOf(), 1, `bids should be 1`);
	});
});
