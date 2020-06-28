const { assert } = require("chai");

const Katie = artifacts.require("./Katie.sol");

require("chai").use(require("chai-as-promised")).should();

contract("Katie", (accounts) => {
	let contract;
	before(async () => {
		contract = await Katie.deployed();
	});

	describe("deployment", async () => {
		it("deploys successfully", async () => {
			const address = contract.address;
			console.log(address);
			assert.notEqual(address, "");
			assert.notEqual(address, 0x0);
			assert.notEqual(address, null);
		});

		it("has a name", async () => {
			// name function is a promise
			const name = await contract.name();
			assert.equal(name, "Katie");
		});

		it("has a symbol", async () => {
			// name function is a promise
			const name = await contract.symbol();
			assert.equal(name, "KATE");
		});
	});

	describe("minting", async () => {
		it("creates a new token", async () => {
			const result = await contract.mint("#EC058E");
			const totalSupply = await contract.totalSupply();
			// console.log(result);
			assert.equal(totalSupply, 1);

			const event = result.logs[0].args;
			// console.log(event);
			assert.equal(event.tokenId.toNumber(), 1, "id is correct");
			assert.equal(event.from, "0x0000000000000000000000000000000000000000", "from is correct");
			assert.equal(event.to, accounts[0], "to is correct");

			// can't mint same color twice
			await contract.mint("#EC058E").should.be.rejected;
		});
	});

	describe("indexing", async () => {
		it("lists colors", async () => {
			// mint 3 more tokens
			await contract.mint("#000000");
			await contract.mint("#FFFFFF");
			await contract.mint("#5386E4");

			let color;
			let result = [];

			const totalSupply = await contract.totalSupply();
			for (let i = 1; i <= totalSupply; i++) {
				// dont forget get colors is a promise
				//// solidity side: string[] public colors mapps to colors(i) getter
				color = await contract.colors(i - 1);
				result.push(color);
			}

			let expected = ["#EC058E", "#000000", "#FFFFFF", "#5386E4"];
			// since compare arrays can be tricky, so convert to string
			assert.equal(expected.join(","), result.join(","));
		});
	});
});
