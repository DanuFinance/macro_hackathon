/* SPDX-License-Identifier: GPL-3.0-or-later */

/*
 * The appraisal API responds in the following format:
 *
 *     {
 *         "type": "price_update",
 *         "payload": {
 *             "fair-market_price": 32.14,
 *             "liquidation_price": 28.03,
 *             "currency": "ETH"
 *         },
 *         "time": "2022-08-23T13:08:09+00:00"
 *     }
 *
 * PLEASE DO NOT USE THIS CODE VERBATIM IN PRODUCTION ENVIRONMENTS. */


pragma solidity ^0.8.16;


import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";


/* User-defined constants; to be made dynamic in a later version of the NFT-AMM */
/* - Endpoint to query using the Chainlink oracle services */
string constant APPRAISAL_REST_ENDPOINT = "https://api.danu.fi/appraise/";
/* - Chainlink-specific variables */
bytes32 constant LINK_JOB_ID = "ca98366cc7314957b8c012c72f05aeeb";
address constant LINK_TOKEN_ADDRESS = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
address constant LINK_ORACLE_ADDRESS = 0xCC79157eb46F5624204f47AB42b3906cAA40eaB7;



contract nftAppraisalOracle is ChainlinkClient, ConfirmedOwner {
	using Chainlink for Chainlink.Request;

	/* - Price; either fair-market or liquidation, depending on user settings */
	uint256 public price;
	/* - Chainlink oracle service variables */
	uint256 private chainlink_fee;

	event PriceRequest(bytes32 indexed _request_ID, uint256 price);

	constructor() ConfirmedOwner(msg.sender) {
		setChainlinkToken(LINK_TOKEN_ADDRESS);
		setChainlinkOracle(LINK_ORACLE_ADDRESS);

		/* Dependent on congestion bla bla bla */
		chainlink_fee = (1 * LINK_DIVISIBILITY) / 10;
	}

	function appraiseNFT(
		address _NFT_contract,
		uint256 _token_ID,
		bool    _is_liquidation_price
	) public returns (bytes32 request_ID) {

		Chainlink.Request memory request = buildChainlinkRequest(
			LINK_JOB_ID,
			address(this),
			this.fulfill.selector
		);

		request.add("get",
			string(abi.encodePacked(
				APPRAISAL_REST_ENDPOINT, _NFT_contract, "/", _token_ID
			))
		);

		/* Add the path, with sanitization to remove decimals, and send the request */
		request.add("path",
			_is_liquidation_price ? "0,payload,liquidation_price" : "0,payload,fair-market_price"
		);
		request.addInt("times", 10**18);

		return sendChainlinkRequest(request, chainlink_fee);

	}

	function fulfill(bytes32 _request_ID, uint256 _price) public recordChainlinkFulfillment(_request_ID) {
		emit PriceRequest(_request_ID, _price);

		price = _price;
	}

	/* @dev Allow withdrawal of Link tokens from the contract */
	function withdrawLinkBalance() public onlyOwner {
		LinkTokenInterface link_interface = LinkTokenInterface(chainlinkTokenAddress());

		require(
			link_interface.transfer(msg.sender, link_interface.balanceOf(address(this))),
			"Unable to withdraw Link tokens"
		);
	}

}

