/* based contract testnet deploy arguments
 * npx hardhat verify --constructor-args scripts/contractArgs.ts  0x9b19319E9bcFf85D106956096286A554a3C43350 --network fantom
 **/
let acropolisAddr: string = '0x4D06f72DdbA5EDaA240e5cc657553e89c2De7944';
let basedTokenAddr: string = '0xeC60C8842feb02CBAA3e882EcDFCb99acAE78D7E';
let bShareTokenAddr: string = '0x3e4bf688aD2F24AAE7EE99f019A95d2Ac77f3c28';
let treasuryAddr: string = '0xbF43880db8cBbA67B520f76FAf3e6f3840B419F1';
let devFundAddr: string = '0xf2D002BB00Ec16215902F3def7e9F20cE3C2332E';
let pairAddr: string = '0x02135471B727c129A2EE8d7416732427849d6a69';
let taxCollectorAddr: string = '0x1252E3f03E0caa840cbb35442d817a1686A62586';
let poolStartTime: number = 1643423634;
let period: number = 0;
let taxRate: number = 0;

let contractArgsMap = new Map<string, any[]>([
    ['Acropolis', []],
    ['Based', [taxRate, taxCollectorAddr]],
    ['Bshare', [poolStartTime, treasuryAddr, devFundAddr]],
    ['FtmLpRewardPool', [basedTokenAddr, poolStartTime]],
    ['FtmLpBshareRewardPool', [basedTokenAddr]],
    ['FTMRewardPool', [basedTokenAddr, poolStartTime]],
    ['BasedGenesisRewardPool', [basedTokenAddr, treasuryAddr, poolStartTime]],
    ['Oracle', [pairAddr, period, poolStartTime]],
    ['BasedRewardPool', [basedTokenAddr, poolStartTime]],
    ['Zap', [basedTokenAddr]],
    ['TaxOffice', ['0x5556B03e542EE4f515ba1A15d9640f0C97AdDe12']],
    ['NNTestToken', ['NNETH', 'NNETH']],
    ['Greeter', ['HOLA!']],
]);

export {contractArgsMap};
