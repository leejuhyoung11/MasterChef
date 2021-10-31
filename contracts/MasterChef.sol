// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol';

import './CakeToken.sol';
import './SyrupBar.sol';


contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    struct UserInfo {
        uint256 amount; // amount of LP tokens
        uint256 rewardDebt; // already rewarded

        // pending reward = (user.amount * pool.accCakePerShare) - user.rewardDebt
    }

    struct PoolInfo {
        IBEP20 lpToken;  // Address of LP token
        uint256 allocPoint; // CAKEs to distribut per block
        uint256 lastRewardBlock; // Last block number that CAKEs distributed
        uint256 accCakePerShare; // Accumulated CAKEs per share
    }

    CakeToken public cake;
    SyrupBar public syrup;
    uint256 public cakePerBlock;
    uint256 public BONUS_MULTIPLIER = 1;
    address public devaddr;

    PoolInfo[] public poolInfo;
    mapping (uint256 => mapping(address => UserInfo)) public userInfo;

    uint256 public totalAllocPoint = 0;
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(CakeToken _cake, SyrupBar _syrup, address _devaddr, uint256 _cakePerBlock, uint256 _startBlock) public {
        cake = _cake; syrup = _syrup; devaddr = _devaddr; cakePerBlock = _cakePerBlock; startBlock = _startBlock;
        // First LP token is CAKE, index : 0
        poolInfo.push(PoolInfo({
            lpToken : _cake, allocPoint : 1000, lastRewardBlock : startBlock, accCakePerShare : 0
        }));
        totalAllocPoint = 1000;
    }

    function updateMultiplier(uint256 multiplierNumber) public {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    function poolLength() external view returns(uint256) { return poolInfo.length; }
    function getLastRewardBlock(uint idx) external view returns(uint256) {return poolInfo[idx].lastRewardBlock;}
    function getBlockNum() public view returns(uint256) {return block.number;}
    function getPoolAlloc(uint idx) public view returns(uint256) {
        return poolInfo[idx].allocPoint;
    }
    function getAccCakePerShare(uint idx) public view returns(uint256) {
        return poolInfo[idx].accCakePerShare;
    }

    function getUserAmount(uint256 _pid) public view returns(uint256) {
        UserInfo storage user = userInfo[_pid][msg.sender];
        return user.amount;
    }

    function getUserRewardDebt(uint256 _pid) public view returns(uint256) {
        UserInfo storage user = userInfo[_pid][msg.sender];
        return user.rewardDebt;
    }

    // Add new lp to the pool, it is OnlyOwner function
    function add(uint256 _allocPoint, IBEP20 _lptoken) public  {
        massUpdatePools();
        
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
            lpToken: _lptoken, 
            allocPoint: _allocPoint, 
            lastRewardBlock: lastRewardBlock, 
            accCakePerShare : 0
        }));
        updateStakingPool();
    }

    // Update CAKE allocation point, it is OnlyOwner function
    function set(uint256 _pid, uint256 _allocPoint) public {
        massUpdatePools();

        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
            updateStakingPool();
        }
    }

    // Deposit LP tokens to MasterChef
    function deposit(uint256 _pid, uint256 _amount) public {
        require(_pid != 0);

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);
        
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) { 
                // Get pending with CAKE token from SyrupBar
                // Get all of current balance in syrup if pending > syrup balance
                safeCakeTransfer(msg.sender, pending);
            }
        }

        if(_amount > 0) {
            pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }

        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }


    // Withdraw LP tokens from MasterChef
    function withdraw(uint256 _pid, uint256 _amount) public {
        require(_pid != 0);

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount);

        updatePool(_pid);

        uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) { safeCakeTransfer(msg.sender, pending); }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }

        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }




    // Update whole pool
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward of the pool
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) return;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        // Calculate LP token reward ratio of cakePerBlock
        uint256 cakeReward = multiplier.mul(cakePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        
        cake.mint(devaddr, cakeReward.div(10));
        cake.mint(address(syrup), cakeReward);

        pool.accCakePerShare = pool.accCakePerShare.add(cakeReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    function getLpSupply(uint256 _pid) public view returns(uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        return lpSupply;
    }

    // For LP Cake pool. it restake accPoint Automatically
    function updateStakingPool() public {
        uint256 length = poolInfo.length;
        uint256 points = 0;

        for (uint256 pid = 1; pid<length; ++pid) {
            points = points.add(poolInfo[pid].allocPoint);
        }
        if (points != 0) {
            points = points.div(3); //why
            totalAllocPoint = totalAllocPoint.sub(poolInfo[0].allocPoint).add(points);
            poolInfo[0].allocPoint = points;
        }

    }
    
    function safeCakeTransfer (address _to, uint256 _amount) internal {
        syrup.safeCakeTransfer(_to, _amount);
    }

}






