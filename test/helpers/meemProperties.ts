import { Permission } from './meemStandard'

export const meemMintData = {
	copyPermissions: [
		{
			permission: Permission.Anyone,
			addresses: [],
			numTokens: 0,
			lockedBy: '0x0000000000000000000000000000000000000000'
		}
	],
	remixPermissions: [
		{
			permission: Permission.Anyone,
			addresses: [],
			numTokens: 0,
			lockedBy: '0x0000000000000000000000000000000000000000'
		}
	],
	readPermissions: [
		{
			permission: Permission.Anyone,
			addresses: [],
			numTokens: 0,
			lockedBy: '0x0000000000000000000000000000000000000000'
		}
	],
	copyPermissionsLockedBy: '0x0000000000000000000000000000000000000000',
	remixPermissionsLockedBy: '0x0000000000000000000000000000000000000000',
	readPermissionsLockedBy: '0x0000000000000000000000000000000000000000',
	splits: [
		{
			toAddress: '0xbA343C26ad4387345edBB3256e62f4bB73d68a04',
			amount: 1000,
			lockedBy: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'
		}
	],
	splitsLockedBy: '0x0000000000000000000000000000000000000000',
	childrenPerWallet: -1,
	childrenPerWalletLockedBy: '0x0000000000000000000000000000000000000000',
	totalChildren: 99,
	totalChildrenLockedBy: '0x0000000000000000000000000000000000000000'
}
