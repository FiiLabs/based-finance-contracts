/* based contract testnet deploy arguments
 * npx hardhat verify --constructor-args scripts/contractArgs.ts  0x9b19319E9bcFf85D106956096286A554a3C43350 --network fantom
 **/
let acropolisAddr: string = '0x4D06f72DdbA5EDaA240e5cc657553e89c2De7944';
let basedTokenAddr: string = '0xA04A9e337dc40B3c2BC03227BA00ade15a34d41b';
let bShareTokenAddr: string = '0xEC692EabF87e1a99f24f769b5eb763f1f7b1D2f4';
let treasuryAddr: string = '0xbF43880db8cBbA67B520f76FAf3e6f3840B419F1';
let devFundAddr: string = '0xf2D002BB00Ec16215902F3def7e9F20cE3C2332E';
let pairAddr: string = '0x56106aade67cf41844d6abaacfd90b05ccf6b1a0';
let taxCollectorAddr: string = '0x1252E3f03E0caa840cbb35442d817a1686A62586';
let bBondTokenAddr: string = '0xe44184F87041C7976fb55e1e27Cd38d887e4cb6F';
let FTMTokenAddr: string = '0x4e15361fd6b4bb609fa63c81a2be19d873717870';
let basedTombLPPairAddrs: string = '0x56106aade67cf41844d6abaacfd90b05ccf6b1a0';
let bShareFTMLPPairAddrs: string = '0xd529bafd74de2a729211667de69fdf58b614184e';
let poolStartTime: number = 1643689323;
let period: number = 360;
let taxRate: number = 0;

let contractArgsMap = new Map<string, any[]>([
    ['Acropolis', []],
    ['Based', [taxRate, taxCollectorAddr]],
    ['BasedTombZap', [bShareTokenAddr]],
    ['contracts/BShareFtmZap.sol:BShareFtmZap', [basedTokenAddr]],
    ['BShare', []],
    ['BBond', []],
    ['Treasury', []],
    ['BShareRewardPool', [bShareTokenAddr, poolStartTime]],
    ['FtmLpRewardPool', [basedTokenAddr, poolStartTime]],
    ['FtmLpBshareRewardPool', [basedTokenAddr]],
    ['FTMRewardPool', [basedTokenAddr, poolStartTime]],
    ['BasedGenesisRewardPool', [basedTokenAddr, treasuryAddr, poolStartTime]],
    ['Oracle', [pairAddr, period, poolStartTime]],
    ['BasedRewardPool', [basedTokenAddr, poolStartTime]],
    ['Zap', [basedTokenAddr]],
    ['TaxOffice', ['0x5556B03e542EE4f515ba1A15d9640f0C97AdDe12']],
    ['NNTestToken', ['TEAMTOK', 'TEAMTOK']],
    ['Greeter', ['HOLA!']],
    ['BasedRewardPool', [basedTokenAddr, poolStartTime]],
    ['BShareSwapper', [basedTokenAddr, bBondTokenAddr, bShareTokenAddr, FTMTokenAddr, basedTombLPPairAddrs, bShareFTMLPPairAddrs, treasuryAddr]],
]);

export {contractArgsMap};
