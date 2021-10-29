const { assert } = require("console");

const MasterChef = artifacts.require("MasterChef");
const CakeToken = artifacts.require("CakeToken");
const SyrupBar = artifacts.require("SyrupBar");
const SampleToken = artifacts.require("SampleToken");

contract('MasterChef', async(accounts) => {
    dev = accounts[0]; user1 = accounts[1]; user2 = accounts[2]; user3 = accounts[3];



    beforeEach(async () => {
        cake = await CakeToken.new();
        syrup = await SyrupBar.new(cake.address);
        masterChef = await MasterChef.new(cake.address, syrup.address, dev, '1000', '100');


        lp1 = await SampleToken.new('LPtoken', 'LP1', '10000');
        lp2 = await SampleToken.new('LPtoken', 'LP2', '10000');

        await lp1.transfer(user1, 2000);
        await lp1.transfer(user2, 500);

    });

    it ('Add lp tokens', async() => {
        // add 2 new lp tokens
        await masterChef.add(1000, lp1.address);
        await masterChef.add(1000, lp2.address);
        assert((await masterChef.poolLength()).toNumber() === 3);

        await lp1.approve(masterChef.address, 300, {from : user1});
        
        
        arr = [20, 0, 40, 0]
        for (i = 0; i<arr.length; i++) {
            await masterChef.deposit(1, arr[i].toString(), {from : user1});
            //console.log(await masterChef.getLpSupply(1));
            console.log('rewardDebt' + await masterChef.getUserRewardDebt(1, {from : user1}));
            //console.log((await masterChef.getAccCakePerShare(1)).toNumber());  
            console.log('cake is ' + (await cake.balanceOf(user1)).toNumber());
        }
        masterChef.withdraw(1, '10', {from : user1});
        //console.log((await lp1.balanceOf(masterChef.address)).toNumber());
        console.log('cake is ' + (await cake.balanceOf(user1)).toString());
    });

    

});
