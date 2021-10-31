const { assert } = require("console");

const MasterChef = artifacts.require("MasterChef");
const CakeToken = artifacts.require("CakeToken");
const SyrupBar = artifacts.require("SyrupBar");
const SampleToken = artifacts.require("SampleToken");

contract('MasterChef', async(accounts) => {
    dev = '0x6191A6a1AE983ac7b9b73767020e212e8BFb32F3'; 
    user1 = "0x32586DB0a999Ba2819533F016602BA183390E523"; 
    user2 = '0x042C906629902356987f66271DD65A67eC223293'; 
    user3 = '0xdA0d5D129F340f28B7F0a506D0Db1758f0cE7214';


    // Deploy CAKE, Syrup Bar, MasterChef, Mock Tokens
    beforeEach(async () => {
        cake = await CakeToken.new();
        syrup = await SyrupBar.new(cake.address);
        masterChef = await MasterChef.new(cake.address, syrup.address, dev, 1000, '100');

        lp1 = await SampleToken.new('LPtoken', 'LP1', '10000');
        lp2 = await SampleToken.new('LPtoken', 'LP2', '10000');
        lp3 = await SampleToken.new('Lptoken', 'LP3', '10000');

        await lp1.transfer(user1, 500);
        await lp1.transfer(user2, 500);

    });


    it ('Add lp tokens', async() => {
        
        // add 3 new lp tokens
        await masterChef.add(1000, lp1.address);
        await masterChef.add(1000, lp2.address);
        await masterChef.add(1000, lp3.address);

        // [CAKE, lp1, lp2, lp3]
        assert((await masterChef.poolLength()).toNumber() === 4);
    });

    it ('Deposit', async() => {
        // add 3 new lp tokens
        await masterChef.add(1000, lp1.address);
        await masterChef.add(1000, lp2.address);
        await masterChef.add(1000, lp3.address);

        // allowance[user1][masterchef] = 300
        await lp1.approve(masterChef.address, 300, {from : user1});
        
        depositAmount = [20, 0, 40, 0];
        // accCakePerSahre = [0, 12.5, 25, 29.16];
        // pending = [0, 250, 250, 249];
        // rewardDebt = [0, 250, 1500, 1749];
        for (i = 0; i<depositAmount.length; i++) {
            await masterChef.deposit(1, depositAmount[i], {from : user1});
        }

        assert((await lp1.balanceOf(user1)).toString() === '440')
        assert((await cake.balanceOf(user1)).toString() === '749');
    });

    // it ('WithDraw', async() => {
    //     // add 3 new lp tokens
    //     await masterChef.add(1000, lp1.address);
    //     await masterChef.add(1000, lp2.address);
    //     await masterChef.add(1000, lp3.address);

    //     // allowance[user1][masterchef] = 300
    //     await lp1.approve(masterChef.address, 300, {from : user1});
        
    //     depositAmount = [20, 0, 40, 0];
    //     for (i = 0; i<depositAmount.length; i++) {
    //         await masterChef.deposit(1, depositAmount[i], {from : user1});
    //     }

    //     await masterChef.withdraw(1, 60, {from : user1});
        
    //     assert((await lp1.balanceOf(user1)).toString() === '500');
    //     assert( (await cake.balanceOf(user1)).toString() === '999');
    // });

    it ('Two Users are Using a pool', async() => {
        await masterChef.add(1000, lp1.address);
        await masterChef.add(1000, lp2.address);
        await masterChef.add(1000, lp3.address);

        await lp1.approve(masterChef.address, 300, {from : user1});
        await lp1.approve(masterChef.address, 300, {from : user2});
        
        await masterChef.deposit(1, 20, {from : user1});
        await masterChef.deposit(1, 30, {from : user2});
        await masterChef.deposit(1, 0, {from : user1});
        await masterChef.deposit(1, 0, {from : user2});

        assert((await cake.balanceOf(user1)).toString() === '350');
        assert((await cake.balanceOf(user2)).toString() === '300');
    });

    
    // div function 나누어 떨어지지 않을떄
});
