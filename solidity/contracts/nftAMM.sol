/* SPDX-License-Identifier: GPL-3.0-or-later */

/* The core of the Danu NFT-AMM.
 *
 * This code does not focus on gas efficiency :) The general idea is best outlined
 * by the following quote:
 *
 * "If a concern can possibly be addressed outside of a smart contract, then
 *                                                  that’s what we should do."
 *                                                           --- R. Hitchens
 *
 * And that's we'll do, using e.g. indices to speed up crawling times.
 *
 * PLEASE DO NOT USE THIS CODE VERBATIM IN PRODUCTION ENVIRONMENTS. */


pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./nftAppraisalOracle.sol";


/* User-defined constants; to be made dynamic in a later version of the NFT-AMM */
/* - LP reward percentage */
uint256 constant LP_REWARD_PERCENTAGE = 1;


/** @title Danu NFT-AMM
 * @dev Depends on nftAppraisalOracle.sol to compute fair-market and liquidation prices */
contract nftAMM is ReentrancyGuard, Ownable, IERC721Receiver {

	using Counters for Counters.Counter;

	enum nftAppraisalType {
		/* The fair-market price, determined using the conventional NFT appraisal algorithm */
		fair_market_price,
		/* Price determined by applying a liquidiation discount to the aforementioned */
		liquidation_price,
		/* List the NFT at a price determined by the seller */
		custom_price
	}

	/* Fungible token (FT) position; assumed to be in Eth for the time being */
	struct FTPosition {
		address payable         owner;
		uint256                 size;
		uint256                 commissions;
		uint256                 timestamp;
		bool                    active;
	}

	/* Non-fungible token (NFT) position */
	struct NFTPosition {
		address                 nft_contract;
		uint256                 token_ID;
		address payable         seller;
		nftAppraisalType        NFT_appraisal_type;
		uint256                 price;
		bool                    active;  /* Listed per definition */
	}

	event NFTListed(NFTPosition);

	event NFTSold(NFTPosition);

	/* @notice All fungible and non-fungible positions */
	/* @doc Can improve the speed of data retrieval using conventional database indexes */
	NFTPosition[] public positions_NFT;
	FTPosition[] public positions_FT;

	/* Administrative variables */
	/* - Cumulative liquidity - to avoid having to sum everything */
	uint256 public CUMULATIVE_LIQUIDITY = 0;
	/* - Appraisal oracle, to be used when NFTAppraisalType != custom_price */
	nftAppraisalOracle private _NFT_appraisal_oracle;

	constructor() {
		_NFT_appraisal_oracle = new nftAppraisalOracle();
	}

	/* Add fungible liquidity to the pool */
	function provideLiquidity() public payable {

		require(msg.value > 0, "Liquidity provided must be non-zero");

		positions_FT.push(
			FTPosition(payable(msg.sender), msg.value, 0, block.timestamp, true)
		);
		CUMULATIVE_LIQUIDITY += msg.value;
	}

	/* Withdraw liquidity from the pool */
	function withdrawLiquidity(bool _is_fungible, uint256 _position_ID) public payable {

		require(
			_position_ID >= 0 && _position_ID < (
				_is_fungible ? positions_FT.length : positions_NFT.length
			)
		);

		/* FTPosition */
		if (_is_fungible) {

			if (positions_FT[_position_ID].active) {
				uint256 cumulative_position_size =
					positions_FT[_position_ID].size +
					positions_FT[_position_ID].commissions;

				positions_FT[_position_ID].active = false;
				CUMULATIVE_LIQUIDITY -= cumulative_position_size;

				payable(positions_FT[_position_ID].owner).transfer(cumulative_position_size);
			}

		/* NFTPosition - We also de-list NFTs sold at liquidation price w/o transferring ownership */
		} else {
			positions_NFT[_position_ID].active = false;

			bool is_owner = (msg.sender == IERC721(
				positions_NFT[_position_ID].nft_contract
			).ownerOf(positions_NFT[_position_ID].token_ID));
			bool is_liquidation_price = (positions_NFT[_position_ID].NFT_appraisal_type ==
				nftAppraisalType.liquidation_price
			);

			if (is_owner && !is_liquidation_price)
				IERC721(positions_NFT[_position_ID].nft_contract).safeTransferFrom(
					address(this), msg.sender, positions_NFT[_position_ID].token_ID
				);

		}
	}

	function swapNFT(
		uint256                 _price,
		address                 _NFT_contract,
		uint256                 _token_ID,
		nftAppraisalType        _NFT_appraisal_type
	) public payable nonReentrant {

		require(msg.sender == IERC721(_NFT_contract).ownerOf(_token_ID), "Wallet doens't own NFT");

		/* Obtain the price the NFT is to be listed at */
		uint256 price;
		if (_NFT_appraisal_type == nftAppraisalType.custom_price) {
			price = _price;
		} else {
			_NFT_appraisal_oracle.appraiseNFT(
				_NFT_contract,
				_token_ID,
				/* What is the state of sharing enums between contracts as of Aug 29, 2022? */
				_NFT_appraisal_type == nftAppraisalType.liquidation_price ? true : false
			);
			price = _NFT_appraisal_oracle.price();
		}

		require(price > 0, "Price must be at least 1 wei");

		/* Transfer ownership to the pool */
		IERC721(_NFT_contract).approve(address(this), _token_ID);
		IERC721(_NFT_contract).safeTransferFrom(msg.sender, address(this), _token_ID);

		/* If the listing is a trade at liquidation price, handle the transaction */
		if (_NFT_appraisal_type == nftAppraisalType.liquidation_price) {
			require(address(this).balance >= price, "Not enough liquidity available");

			/* Tally LP liquidity - they're the ones who made this possible */
			for (uint256 i=0; i < positions_FT.length; i++)
				if (positions_FT[i].active)
					positions_FT[i].commissions += (
						(positions_FT[i].size / CUMULATIVE_LIQUIDITY)
						*
						(LP_REWARD_PERCENTAGE * price)
					);

			/* Transfer Eth to the seller for the discounted price */
			payable(msg.sender).transfer((100 - LP_REWARD_PERCENTAGE) * price / 100);
		}

		NFTPosition memory nft = NFTPosition(
			_NFT_contract,
			_token_ID,
			payable(msg.sender),
			_NFT_appraisal_type,
			price,
			true
		);

		/* Sanitize administration */
		/* - List the NFT */
		positions_NFT.push(nft);
		/* - Emit the event */
		emit NFTListed(nft);
	}

	function buyNFT(uint256 _listing_ID) public payable nonReentrant {
		NFTPosition storage nft = positions_NFT[_listing_ID];

		require(msg.value >= nft.price, "Insufficient funds to purchase NFT");

		/* Transfer the Eth to the pool if the pool owns it (because the owner sold the NFT for
	         * its liquidation price), and to the seller if the seller "owns" it. */
		payable(
			nft.NFT_appraisal_type == nftAppraisalType.liquidation_price
			? address(this)
			: nft.seller
		).transfer(msg.value);

		/* Transfer ownership of contract; the pool always owns the contract */
		IERC721(nft.nft_contract).safeTransferFrom(address(this), msg.sender, nft.token_ID);

		/* Sanitize administration */
		/* - Unlist the NFT */
		positions_NFT[_listing_ID].active = false;
		/* - Emit event so that the whole world knows you've bought a fancy new NFT */
		emit NFTSold(nft);
	}

	/* @dev Must implement per ERC721 to allow smart contracts to receive ERC721 NFTs */
	function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external pure returns (bytes4) {
		return IERC721Receiver.onERC721Received.selector;
	}

	function withdrawCommissionBalance(uint256 amount) public onlyOwner {
		require(amount <= address(this).balance, "Don't have that many funds");

		payable(msg.sender).transfer(amount);
	}

	function getNPositions(bool _is_fungible) public view returns (uint256) {
		return _is_fungible ? positions_FT.length : positions_NFT.length;
	}


}

