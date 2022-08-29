/* Written for Danu, 2022 */


/* Buy popup for each NFT. Rather than attaching to every single button, attach to its
 * parent per https://stackoverflow.com/a/28106038 and take it from there */
document.getElementById("nft-grid").addEventListener("click", (event) => {
	/* Traverse DOM tree until closest button is found, see
	 * https://www.jsdiaries.com/how-to-loop-through-parent-nodes-in-javascript/ */
	var button = event.target.closest("button");

	/* Get values from the DOM; intentionally do not ask the oracle to update the price
	 * to prevent a discrepancy that cannot be handled appropriately now
	 * without a socket connection and more involved SC logic */
	if (button !== null)
		popup({
			title: button.querySelector('figcaption h3').innerText,
			closeable: true,
			message: "Fancy confirmation message"
		});
});


/* Faucet that gives the user n NFTs */
async function faucet_NFTs() {
	var n_NFTs_to_mint = 1;

	var accounts = await web3.eth.getAccounts();

	contracts.nftTestCollection.methods.mintNFTs(n_NFTs_to_mint).send({
		from: accounts[0]
	}).on("receipt", () => {
		popup({
			title: `Faucet minted ${n_NFTs_to_mint} NFTs`,
			closeable: true,
			message: "Have fun exploring Danu!"
		});
	});
}


/* Load all listed NFTs */

