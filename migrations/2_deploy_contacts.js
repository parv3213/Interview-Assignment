const DemurrageERC721 = artifacts.require('DemurrageERC721');
const MockToken = artifacts.require('MockToken');

module.exports = async (deployer, network, accounts) => {
	deployer.then(async () => {
		mockToken = await deployer.deploy(MockToken);
		deployer.deploy(DemurrageERC721, accounts[0], mockToken.address);
	});
};
