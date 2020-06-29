var DeedRepository = artifacts.require("./DeedRepository.sol");
const fs = require("fs");

contract("DeedRepository", async (accounts) => {
	/**
	 * before() is run once before all the tests in a describe
	 * after()   is run once after all the tests in a describe
	 * beforeEach() is run before each test in a describe
	 * afterEach()   is run after each test in a describe
	 */

	let instance;
	let auctionContractAddress = "";

	beforeEach("setup contract for each test", async function () {
		instance = await DeedRepository.deployed();
		auctionContractAddress = fs.readFileSync("./test/output.address").toString();
	});

	it("It should create an deed repository with KATE as symbol", async () => {
		let symbol = await instance.symbol();
		// about valueOf: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/valueOf
		assert.equal(symbol.valueOf(), "KATE", `Deedrepository symbol should be KATE`);
	});

	// regard to token uri
	// http://kojiryo.com/1438/
	it("It should register a deed with id: 123456789", async () => {
		await instance.registerDeed(123456789, "Katie:123456789");
		let ownerOfDeed = await instance.exists(123456789);
		assert.equal(ownerOfDeed.valueOf(), true, `Result should be true`);
	});

	it(`It should check owner of 123456789 who is ${accounts[0]}`, async () => {
		let ownerOfDeed = await instance.ownerOf(123456789);
		assert.equal(ownerOfDeed.valueOf(), accounts[0], `Owner should be ${accounts[0]}`);
	});

	it(`It should check balance of ${accounts[0]}`, async () => {
		let balance = await instance.balanceOf(accounts[0]);
		assert.equal(balance.valueOf(), 1, `balance ${balance} should be 1`);
	});

	it(`It should check total supply of the repository`, async () => {
		let supply = await instance.totalSupply();
		assert.equal(supply.valueOf(), 1, `total supply: ${supply} should be 1`);
	});

	it(`It should approve transfer the ownership of 123456789 to the auctionRepository address`, async () => {
		// function approve(address to, uint256 tokenId)
		await instance.approve(auctionContractAddress, 123456789);
		// console.log('this auction address:', auctionAddress, ' deedrepo instance addr', instance.address);
		let address = await instance.getApproved(123456789);
		assert.equal(address.valueOf(), auctionContractAddress, `${address} should be equal to ${auctionContractAddress}`);
	});

	it("It should transfer ownership of deed 123456789 to this contract", async () => {
		await instance.transferFrom(accounts[0], auctionContractAddress, 123456789, { from: accounts[0] });
		let newOwnerAddress = await instance.ownerOf(123456789);
		//let success = await instance.isApprovedOrOwner(auctionAddress, 123456789)
		assert.equal(newOwnerAddress.valueOf(), auctionContractAddress, `${newOwnerAddress} should be ${auctionContractAddress}`);
	});
});
