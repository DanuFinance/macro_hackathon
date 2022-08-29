/* SPDX-License-Identifier: GPL-3.0-or-later */

/* This is a generic NFT test collection to make the NFT marketplace look pretty. The artwork
 * and metadata have been provided to us by a good friend of mine who wished to remain
 * anonymous. You know who you are ;)
 *
 * PLEASE DO NOT USE THIS CODE VERBATIM IN PRODUCTION ENVIRONMENTS. */

/* https://docs.openzeppelin.com/contracts/4.x/erc721 */


pragma solidity ^0.8.16;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


/* User-defined variables */
/* - Base URI for the collection */
string constant BASE_URL = "https://testnet.danu.fi/nftTestCollection/";
/* - Maximum number of NFTs a address is allowed to mint */
uint256 constant N_MAX_NFTS_PER_ADDRESS = 10;


/* @dev Conforms to ERC721 */
contract nftTestCollection is ERC721URIStorage {
	using Counters for Counters.Counter;
	using Strings for uint256;

	Counters.Counter private _tokenIDs;

	address NFT_AMM;

	mapping(address => uint256) n_NFTs_for_address;

	constructor(address _NFT_AMM) ERC721("nftTestCollection", "DNTC") {
		NFT_AMM = _NFT_AMM;
	}

	function totalSupply() external view returns (uint256) {
		return _tokenIDs.current();
	}

	function mintNFTs(uint256 n_NFTs) public {

		require(n_NFTs_for_address[msg.sender] < N_MAX_NFTS_PER_ADDRESS);

		for (uint i=0; i < n_NFTs; i++) {
			_tokenIDs.increment();
			_safeMint(msg.sender, _tokenIDs.current());
			_setTokenURI(
				_tokenIDs.current(),
				string(abi.encodePacked(BASE_URL, _tokenIDs.current().toString(), ".json"))
			);

			n_NFTs_for_address[msg.sender] += 1;
		}

		setApprovalForAll(NFT_AMM, true);
	}
}

