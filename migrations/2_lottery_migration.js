const Lottery = artifacts.require("Lottery");

module.exports = function (deployer) {
                        // Entry price in ether, maximum entry per address, minimum entry to end the lottery
  deployer.deploy(Lottery, 1, 2, 5);
};
