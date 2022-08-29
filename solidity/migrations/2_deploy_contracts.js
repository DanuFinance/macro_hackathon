/* Written for Danu, 2022 */

const nftAMM = artifacts.require("nftAMM");
const nftAppraisalOracle = artifacts.require("nftAppraisalOracle");
const nftTestCollection = artifacts.require("nftTestCollection");

module.exports = async function(deployer) {
	await deployer.deploy(nftAMM);
	const nft_amm = await nftAMM.deployed();
	await deployer.deploy(nftAppraisalOracle);
	await deployer.deploy(nftTestCollection, nft_amm.address);
};

