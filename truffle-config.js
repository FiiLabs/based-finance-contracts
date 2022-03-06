module.exports = {
    networks: {
        development: {
            host: '127.0.0.1',
            port: 8545,
            network_id: '*', // Match any network id
        },
        fantom: {
            host: 'https://rpc.ftm.tools/',
            accounts: [`${process.env.METAMASK_KEY}`],
            // gasMultiplier: 2,
        },
    },
    compilers: {
        solc: {
            version: '^0.8.0',
        },
    },
};
