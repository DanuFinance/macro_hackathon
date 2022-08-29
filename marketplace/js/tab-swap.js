/* Written for Danu, 2022 */


"use strict";


/* Change the phrasing of the interface upon selection of an appraisal mechanism */
document.getElementById("select_pricing_mechanism").addEventListener("change", (event) => {

	var words = [];

	switch (event.target.value) {
		case "fair-market_price":
			words[0] = "List";
			words[1] = "at";
			words[2] = "of currently";
			break;

		case "liquidation_price":
			words[0] = "Swap";
			words[1] = "for";
			words[2] = "of currently";
			break;

		case "custom_price":
			words[0] = "List";
			words[1] = "at";
			words[2] = "of";
			break;
	}

	/* Should probably change this to avoid indices */
	for (let i = 0; i < words.length; i++)
		document.getElementById(`word_${i}`).textContent = words[i];
});


/* Populate select, intercept submission, and handle swap */

