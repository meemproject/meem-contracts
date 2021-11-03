import { ethers as Ethers } from 'ethers'

export enum FacetCutAction {
	Add = 0,
	Replace = 1,
	Remove = 2
}

export interface Contract {
	args?: (string | number | (() => string | undefined))[]
	address?: string
	libraries?: Record<string, string>
	waitForConfirmation?: boolean
}

export interface IDeployHistoryFacet {
	address: string
	functionSelectors: string[]
}

// get function selectors from ABI
export function getSelectors(contract: Ethers.Contract): string[] {
	const signatures: string[] = Object.keys(contract.interface.functions)

	return signatures.reduce((acc: any[], val: string) => {
		if (val !== 'init(bytes)') {
			acc.push(contract.interface.getSighash(val))
		}
		return acc
	}, [])
}

export function getSelector(func: string, ethers: any) {
	const abiInterface = new ethers.utils.Interface([func])
	return abiInterface.getSighash(ethers.utils.Fragment.from(func))
}

export function getSighashes(selectors: string[], ethers: any): string[] {
	if (selectors.length === 0) return []
	const sighashes: string[] = []
	selectors.forEach(selector => {
		if (selector !== '') sighashes.push(getSelector(selector, ethers))
	})
	return sighashes
}

// // get function selector from function signature
// function getSelector(func) {
// 	const abiInterface = new ethers.utils.Interface([func])
// 	return abiInterface.getSighash(ethers.utils.Fragment.from(func))
// }

// // used with getSelectors to remove selectors from an array of selectors
// // functionNames argument is an array of function signatures
// function remove(functionNames) {
// 	const selectors = this.filter(v => {
// 		for (const functionName of functionNames) {
// 			if (v === this.contract.interface.getSighash(functionName)) {
// 				return false
// 			}
// 		}
// 		return true
// 	})
// 	selectors.contract = this.contract
// 	selectors.remove = this.remove
// 	selectors.get = this.get
// 	return selectors
// }

// // used with getSelectors to get selectors from an array of selectors
// // functionNames argument is an array of function signatures
// function get(functionNames) {
// 	const selectors = this.filter(v => {
// 		for (const functionName of functionNames) {
// 			if (v === this.contract.interface.getSighash(functionName)) {
// 				return true
// 			}
// 		}
// 		return false
// 	})
// 	selectors.contract = this.contract
// 	selectors.remove = this.remove
// 	selectors.get = this.get
// 	return selectors
// }

// // remove selectors using an array of signatures
// function removeSelectors(selectors, signatures) {
// 	const iface = new ethers.utils.Interface(signatures.map(v => `function ${v}`))
// 	const removeSelectors = signatures.map(v => iface.getSighash(v))
// 	selectors = selectors.filter(v => !removeSelectors.includes(v))
// 	return selectors
// }

// // find a particular address position in the return value of diamondLoupeFacet.facets()
// function findAddressPositionInFacets(facetAddress, facets) {
// 	for (let i = 0; i < facets.length; i++) {
// 		if (facets[i].facetAddress === facetAddress) {
// 			return i
// 		}
// 	}
// }
