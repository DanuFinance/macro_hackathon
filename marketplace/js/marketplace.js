/* Written for Danu, 2022 */

/* Functionality common to all marketplace tabs */

const menu_items = document.querySelectorAll('aside ul[role="doc-toc"] button');

const tabs = document.getElementsByClassName('tabs');

var contracts = {
	nftAMM: null,
	nftTestCollection: null
};

var web3;


/* Convience function for showing popups */
function popup(params = {
	title: "Lorem ipsum dolor sit amet",
	closeable: true,
	message: ""
}) {
	document.body.insertAdjacentHTML(`beforeend`, `
		<div class="popup-wrapper">
			<div class="popup-contents signup-metamask">
				<div class="title_bar">
					<span>${params['title']}</span>
					<button class="close"` + (!params['closeable'] ? ' disabled' : '') + `><svg viewBox="0 0 320 512"><use href="assets/icons.svg#xmark"/></svg>Close</button>
				</div>
				<div class="message">
					${params['message']}
				</div>
			</div>
		</div>
	`);

	if (params['closeable']) {
		document.onkeydown = (event) => {
			if (event.key === "Escape")
				document.querySelector('.popup-wrapper').remove();
		};

		document.querySelector('.popup-wrapper button.close').onclick = (event) => {
			document.querySelector('.popup-wrapper').remove();
		}
	}
}


/* Implements tab switching (i.e. "Discover", "Swap", "Provide liquidity") functionality */
function switch_tab(event) {
	[...menu_items].forEach(button => {
		button.setAttribute('aria-current', button.id === event.target.id ? true : false);
	});

	[...tabs].forEach((tab) => {
		tab.setAttribute('aria-current', tab.id === event.target.id ? true : false);
	});
}


/* Wallet connection - best you can do as no reliable way exists to handle disconnections */
async function connect_wallet() {
	if (window.ethereum) {
		try {
			await window.ethereum.request({
				method: "eth_requestAccounts"
			});

			document.getElementById("connect_wallet").disabled = true;
			document.getElementById("wallet-connection-text").innerText = "Wallet connected";

			web3 = new Web3(window.ethereum);

			/* Remove placeholder data */
			[...document.querySelectorAll('.placeholder')].forEach((item) => {
				item.remove();
			});

			/* Setup Web3 app, loading its ABI */
			/* Local addresses, have to be changed to Görli */
			[["nftAMM", "0x229e2c0fAFb2Daf6B5939cc16dEeE77A2CA9bff8"],
			 ["nftTestCollection", "0xfe21a9281fF9919d003cF56D739F877D9d733aa2"]
			].forEach((tup) => {
				fetch(`/js/contracts/${tup[0]}.json`)
					.then((response) => response.json())
					.then((data) => {
						contracts[tup[0]] = new web3.eth.Contract(data.abi, tup[1]);
					});
			});

		} catch (error) {
			popup({
				title: "MetaMask error",
				closeable: false,
				message: "User denied account access."
			});
		}
	} else {
		popup({
			title: "MetaMask error",
			closeable: false,
			message: "No web3.js"
		});
	}
}

