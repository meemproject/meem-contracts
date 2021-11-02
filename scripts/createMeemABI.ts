import path from 'path'
import fs from 'fs-extra'
import accessControlABI from '../abi/contracts/Meem/facets/AccessControlFacet.sol/AccessControlFacet.json'
import erc721ABI from '../abi/contracts/Meem/facets/ERC721Facet.sol/ERC721Facet.json'
import meemABI from '../abi/contracts/Meem/facets/MeemFacet.sol/MeemFacet.json'
import meemDiamondABI from '../abi/contracts/MeemDiamond.sol/MeemDiamond.json'

const combinedABI = [
	...accessControlABI,
	...erc721ABI,
	...meemABI,
	...meemDiamondABI
]

fs.writeFileSync(
	path.join(process.cwd(), 'abi', 'Meem.json'),
	JSON.stringify(combinedABI)
)
