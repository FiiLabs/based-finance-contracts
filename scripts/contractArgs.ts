/* based contract testnet deploy arguments
 * npx hardhat verify --constructor-args scripts/contractArgs.ts  0x9b19319E9bcFf85D106956096286A554a3C43350 --network fantom
 **/
let acropolisAddr: string = '0x4D06f72DdbA5EDaA240e5cc657553e89c2De7944';
let basedTokenAddr: string = '0x1252E3f03E0caa840cbb35442d817a1686A62586';
let bShareTokenAddr: string = '0x3e4bf688aD2F24AAE7EE99f019A95d2Ac77f3c28';
let treasuryAddr: string = '0xc4ec4d4A2CF16E9e4C473dAB6f12AD04D719098c';
let devFundAddr: string = '0xf2D002BB00Ec16215902F3def7e9F20cE3C2332E';
let pairAddr: string = '0x7f0fae34de2b34d13da640afc2273366919cd0b2';
let taxCollectorAddr: string = '0x1252E3f03E0caa840cbb35442d817a1686A62586';
let poolStartTime: number = Math.round(Date.now() / 1000) + 100; // returns current time + 100s

let contractArgsMap = new Map<string, any[]>([
    ['Acropolis', []],
    ['BasedToken', [0, taxCollectorAddr]],
    ['Bshare', [poolStartTime, treasuryAddr, devFundAddr]],
    ['FtmLpRewardPool', [basedTokenAddr, poolStartTime]],
    ['FtmLpBshareRewardPool', [basedTokenAddr]],
    ['FTMRewardPool', [basedTokenAddr, poolStartTime]],
    ['GenesisRewardPool', [basedTokenAddr, poolStartTime]],
    ['Oracle', [pairAddr, 0, poolStartTime]],
    ['TokenRewardPool', [basedTokenAddr, poolStartTime]],
]);
export default contractArgsMap;
