pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./owner/Operator.sol";

contract ProfitDistribution is Operator {
    using SafeERC20 for IERC20;

    string public name = "ProfitDistribution"; // call it ProfitDistribution

    IERC20 public depositToken;
    address public burnAddress;
    uint256 public totalStaked;
    uint256 public depositFee;
    uint256 public totalBurned;

    address[] public stakers;

    struct RewardInfo {
        IERC20 token;
        uint256 rewardsPerEpoch;
        uint256 totalRewards;
        bool isActive;
    }

    struct UserInfo {
        uint256 balance;
        bool hasStaked;
        bool isStaking;
        mapping(uint256 => uint256) pendingRewards; // Maps rewardPoolId to amount
    }

    RewardInfo[] public rewardInfo;
    mapping(address => UserInfo) public userInfo;

    // in constructor pass in the address for reward token 1 and reward token 2
    // that will be used to pay interest
    constructor(IERC20 _depositToken) {
        depositToken = _depositToken;
        burnAddress = 0x000000000000000000000000000000000000dEaD;
        //deposit fee default at 1%
        depositFee = 1000;

        //totalBurned to 0

        totalBurned = 0;
    }

    //Events

    event UpdateDepositFee(uint256 _depositFee);
    event AddReward(IERC20 _token);
    event UpdateBurnAddress(address _burnAddress);
    event UpdateRewardsPerEpoch(uint256 _rewardId, uint256 _amount);

    event RewardIncrease(uint256 _rewardId, uint256 _amount);
    event RewardDecrease(uint256 _rewardId, uint256 _amount);

    event TotalStakedIncrease(uint256 _amount);
    event TotalStakedDecrease(uint256 _amount);

    event UserStakedIncrease(address _user, uint256 _amount);
    event UserStakedDecrease(address _user, uint256 _amount);

    event PendingRewardIncrease(address _user, uint256 _rewardId, uint256 _amount);
    event PendingRewardClaimed(address _user);


    //update deposit fee

    function updateDepositFee(uint256 _depositFee) external onlyOperator {
        require(_depositFee < 3000, "deposit fee too high");
        depositFee = _depositFee;
        emit UpdateDepositFee(_depositFee);
    }

    //add more reward tokens
    function addReward(IERC20 _token) external onlyOperator {
        rewardInfo.push(RewardInfo({
        token: _token,
        rewardsPerEpoch: 0,
        totalRewards: 0,
        isActive: false
        }));

        emit AddReward(_token);
    }

    // Update burn address
    function updateBurnAddress(address _burnAddress) external onlyOperator {
        burnAddress = _burnAddress;
        emit UpdateBurnAddress(_burnAddress);
    }

    // update the rewards per Epoch of each reward token
    function updateRewardsPerEpoch(uint256 _rewardId, uint256 _amount) external onlyOperator {
        RewardInfo storage reward = rewardInfo[_rewardId];

        // checking amount
        require(_amount < reward.totalRewards,"amount must be lower than totalRewards");

        // update rewards per epoch
        reward.rewardsPerEpoch = _amount;

        if (_amount == 0) {
            reward.isActive = false;
        } else {
            reward.isActive = true;
        }

        emit UpdateRewardsPerEpoch(_rewardId, _amount);
    }

    // supply rewards to contract
    function supplyRewards(uint256 _rewardId, uint256 _amount) external onlyOperator {
        RewardInfo storage reward = rewardInfo[_rewardId];

        require(_amount > 0, "amount must be > 0");

        // Update the rewards balance in map
        reward.totalRewards += _amount;
        emit RewardIncrease(_rewardId, _amount);

        // update status for tracking
        if (reward.totalRewards > 0 && reward.totalRewards > reward.rewardsPerEpoch) {
            reward.isActive = true;
        }

        // Transfer reward tokens to contract
        reward.token.safeTransferFrom(msg.sender, address(this), _amount);


    }


    //withdraw rewards out of contract
    function withdrawRewards(uint256 _rewardId, uint256 _amount) external onlyOperator {
        RewardInfo storage reward = rewardInfo[_rewardId];

        require(_amount <= reward.totalRewards, "amount should be less than total rewards");

        // Update the rewards balance in map
        reward.totalRewards -= _amount;
        emit RewardDecrease(_rewardId, _amount);

        // update status for tracking
        if (reward.totalRewards == 0 || reward.totalRewards < reward.rewardsPerEpoch) {
            reward.isActive = false;
        }

        // Transfer reward tokens out of contract
        reward.token.safeTransfer(msg.sender, _amount);
    }

    function stakeTokens(uint256 _amount) external {
        address _sender = msg.sender;
        UserInfo storage user = userInfo[_sender];

        require(_amount > 0, "can't stake 0");

        // 1% fee calculation
        uint256 feeAmount = _amount * depositFee / 100000;
        uint256 depositAmount = _amount - feeAmount;

        //update totalBurned
        totalBurned += totalBurned;

        // Update the staking balance in map
        user.balance += depositAmount;
        emit UserStakedIncrease(_sender, depositAmount);

        //update TotalStaked
        totalStaked += depositAmount;
        emit TotalStakedIncrease(depositAmount);

        // Add user to stakers array if they haven't staked already
        if(!user.hasStaked) {
            stakers.push(_sender);
        }

        // Update staking status to track
        user.isStaking = true;
        user.hasStaked = true;

        // Transfer based tokens to contract for staking
        depositToken.safeTransferFrom(_sender, address(this), _amount);

        // burn based
        depositToken.safeTransfer(burnAddress, feeAmount);
    }

    // allow user to unstake total balance and withdraw USDC from the contract
    function unstakeTokens(uint256 _amount) external {
        address _sender = msg.sender;
        UserInfo storage user = userInfo[_sender];

        require(_amount > 0, "can't unstake 0");

        //check if amount is less than balance
        require(_amount <= user.balance, "staking balance too low");

        //update user balance
        user.balance -= _amount;
        emit UserStakedDecrease(_sender, _amount);

        //update totalStaked
        totalStaked -= _amount;
        emit TotalStakedDecrease(_amount);

        // update the staking status
        if (user.balance == 0) {
            user.isStaking = false;
        }

        // transfer staked tokens out of this contract to the msg.sender
        depositToken.safeTransfer(_sender, _amount);
    }

    function issueInterestToken(uint256 _rewardId) public onlyOperator {
        RewardInfo storage reward = rewardInfo[_rewardId];
        require(reward.isActive, "No rewards");

        for (uint256 i = 0; i < stakers.length; ++ i) {
            address recipient = stakers[i];
            UserInfo storage user = userInfo[recipient];
            uint256 poolShare = getPoolShare(recipient);
            uint256 rewards = poolShare * reward.rewardsPerEpoch / (1e18);

            // distribute income proportionally to their staked amount.

            if(rewards > 0) {

                //update pendingRewards
                user.pendingRewards[_rewardId] += rewards;
                emit PendingRewardIncrease(recipient,_rewardId, rewards);

                //update totalRewards
                reward.totalRewards -= rewards;
                emit RewardDecrease(_rewardId, rewards);
            }

        }

        if (reward.totalRewards == 0 || reward.totalRewards < reward.rewardsPerEpoch) {
            reward.isActive = false;
        }
    }

    //get pending rewards
    function getPendingRewards(uint256 _rewardId, address _user) external view returns(uint256) {
        UserInfo storage user = userInfo[_user];
        return user.pendingRewards[_rewardId];
    }


    //collect rewards

    function collectRewards() external {

        address _sender = msg.sender;


        UserInfo storage user = userInfo[_sender];

        //update pendingRewards and collectRewards

        //loop through the reward IDs
        for(uint256 i = 0; i < rewardInfo.length; ++i)
        //if pending rewards is not 0
            if (user.pendingRewards[i] > 0){

                RewardInfo storage reward = rewardInfo[i];
                uint256 rewardsClaim = user.pendingRewards[i];

                //reset pending rewards
                user.pendingRewards[i] = 0;

                //send rewards
                emit PendingRewardClaimed(_sender);
                reward.token.safeTransfer(_sender, rewardsClaim);
            }
    }

    //get the pool share of a staker
    function getPoolShare(address _user) public view returns(uint256) {
        return (userInfo[_user].balance * (1e18)) / totalStaked;
    }

    function distributeRewards() external onlyOperator {
        uint256 length = rewardInfo.length;
        for (uint256 i = 0; i < length; ++ i) {
            if (rewardInfo[i].isActive) {
                issueInterestToken(i);
            }
        }
    }

}