module.exports = {
	networks: {
		development: {
			host: "localhost",
			port: 7545,
			network_id: "*",
			gas: 3000000,
		},
	},
	compilers: {
		solc: {
			version: "^0.6.0",
			optimizer: {
				enabled: true,
				runs: 200,
			},
		},
	},
};
