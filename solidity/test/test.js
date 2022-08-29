/* Written for Danu, 2022 */

/* Don't forget to use `truffle test --show-events` */

const BN = web3.utils.BN;

const nftAMM = artifacts.require("nftAMM");
const nftAppraisalOracle = artifacts.require("nftAppraisalOracle");
const nftTestCollection = artifacts.require("nftTestCollection");

const verbose = true;


contract("nftAMM", (accounts) => {

	const liquidity_amount = web3.utils.toBN(123);
	const n_NFTs_to_mint = web3.utils.toBN(5);

	let alice = accounts[0];
	let bob = accounts[1];

	before(async () => {
		nft_amm = await nftAMM.deployed();
		nft_test_collection = await nftTestCollection.deployed();

		console.log(`\tAlices' balance: ${await web3.eth.getBalance(alice).then(web3.utils.fromWei)} Eth`);

		console.log(
			"Addresses:\n",
			`\t\tnft_amm: ${nft_amm.address}\n`,
			`\t\tnft_test_collection: ${nft_test_collection.address}`
		);
	});

	describe("Management of liquidity (simplified for testnet, i.e. without commissions)", async () => {
		it("Can a user, e.g. Alice, add liquidity?", async () => {
			await nft_amm.provideLiquidity({
				from: alice,
				value: liquidity_amount
			});

			var res = await nft_amm.CUMULATIVE_LIQUIDITY.call();

			assert.equal(res.toNumber(), liquidity_amount.toNumber());
		});

		it("Can Alice withdraw fungible liquidit?", async () => {
			/* _position_ID 0 */
			await nft_amm.withdrawLiquidity(true, 0, {from: alice});

			var res = await nft_amm.CUMULATIVE_LIQUIDITY.call();

			assert.equal(res.toString(), web3.utils.toBN(0));
		});
	});

	describe("NFT functionality", async () => {
		it("Can Bob mint a couple of NFTs?", async () => {
			await nft_test_collection.mintNFTs(n_NFTs_to_mint, {from: bob});
			var total_supply = await nft_test_collection.totalSupply();

			assert.equal(n_NFTs_to_mint.toNumber(), total_supply.toNumber());
		});

		/* Buying at fair-market and liquidity prices cannot be demonstrated locally */
		it("Can Bob list an NFT of his at a custom price?", async () => {
			await nft_amm.swapNFT(
				123,
				nftTestCollection.address,
				1,
				web3.utils.toBN(2),
				{ from: bob }
			);

			var owner = await nft_test_collection.ownerOf(1);

			assert.equal(owner, nft_amm.address);
		});

		it("Can Alice buy an NFT from Bob?", async () => {
			await nft_amm.buyNFT(0, {from: alice, value: 125})

			var owner = await nft_test_collection.ownerOf(1);

			assert.equal(owner, alice);
		});
	});
});

