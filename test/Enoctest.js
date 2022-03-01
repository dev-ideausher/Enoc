const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

describe('EnocTest', () => {
    beforeEach(async () => {
        // code to run before each test (setup)
        this.ENOC = await ethers.getContractFactory("EnotNFT");
        this.enoc = await this.ENOC.deploy("Enoc", "Enoc", "www.mytoken/", 100000);
        await this.enoc.deployed(); 
    });
    context('Functions', () => {
        it('has an owner', async () => {
            const [owner, addr1, addr2, addr3] = await ethers.getSigners();
            this.owner = owner;
            const ownerAddress = await this.enoc.owner();
            assert.equal(ownerAddress, owner.address);
        });
        it('Sets the Sale state', async () => {
            await this.enoc.setSaleState(true);
            const saleState = await this.enoc.isSaleActive();
            assert.equal(saleState, true);
        });
        it('Set the allow list state', async () => {
            await this.enoc.setIsAllowListActive(true);
            const allowListState = await this.enoc.isAllowListActive();
            assert.equal(allowListState, true);
        });
        it('set a new Base URI', async () => {
            await this.enoc.setBaseURI("www.metadata/");
            const baseURI = await this.enoc.baseTokenURI();
            assert.equal(baseURI, "www.metadata/");
        });
        it('Add user to whiteList', async () => {
            const [owner, addr1, addr2, addr3] = await ethers.getSigners();
            await this.enoc.addUser(addr1.address);
            const isUserInWhiteList = await this.enoc.verifyUser(addr1.address);
            assert.equal(isUserInWhiteList, true);
        });
        it('Adds array of users to whiteList', async () => {
            const [owner, addr1, addr2, addr3, addr4, addr5, addr6] = await ethers.getSigners();
            await this.enoc.addArrayOfUsers([addr1.address, addr2.address, addr3.address, addr4.address, addr5.address]);
            const isUserInWhiteList = await this.enoc.verifyUser(addr5.address);
            assert.equal(isUserInWhiteList, true);
        });
        it('Contract Pause', async () => {
            await this.enoc.pause();
            const isPaused = await this.enoc.paused();
            assert.equal(isPaused, true);
        });
        it('Contract Unpause', async () => {
            await this.enoc.pause();
            await this.enoc.unpause();
            const isPaused = await this.enoc.paused();
            assert.equal(isPaused, false);
        });
        it('Set the Mint Price', async () => {
            // const amount = ethers.utils.parseUnits("1000", 18);    // 1000 ETH 
            await this.enoc.setMintPrice(10);
            const mintPrice = await this.enoc.price();
            // const mintPrice = mintPrice.ethers.utils.
            assert.equal(mintPrice, 10);
        });
    });
    context('Minting the tokens', () => {
        beforeEach(async () => {
            await this.enoc.setSaleState(true);
            await this.enoc.setIsAllowListActive(true);
            const [owner, addr1, addr2, addr3, addr4, addr5, addr6] = await ethers.getSigners();
            await this.enoc.addArrayOfUsers([addr1.address, addr2.address, addr3.address, addr4.address, addr5.address]);
            await this.enoc.mint(3);
        })
    })
})