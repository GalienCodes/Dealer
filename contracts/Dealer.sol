// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/ICrossDomainEnabled.sol";
import "../interface/ILockingPool.sol";
import "../interface/IVeMetisMinter.sol";
import "../interface/ICrossDomainMessenger.sol";
import "./SequencerAgent.sol";


/// @title Dealer
/// @notice The Dealer contract is responsible for the allocation of Metis tokens from Layer 2 to the LockingPool for sequencers, through sequencer agents.
contract Dealer is OwnableUpgradeable {

    /// @notice Emits when a new sequencer agent is added
    /// @param index index of the agent
    /// @param agent address of the agent
    event SequencerAgentAdded(uint32 index, address agent);

    /// @notice Emits when additional Metis tokens and rewards are locked for a sequencer.
    /// @param index The index of the sequencer agent in the sequencer list.
    /// @param amount The amount of Metis tokens that have been added to the lock.
    /// @param reward The amount of additional rewards that have been locked.
    event SequencerRelocked(uint32 index, uint256 amount, uint256 reward);

    /// @notice Emits when Metis tokens are minted on Layer 2.
    /// @param amount The amount of Metis tokens that have been minted.
    event L2MetisMinted(uint256 amount);

    /// @notice Emits when the sequencer agent template is set.
    /// @param oldValue The address of the old sequencer agent template.
    /// @param newValue The address of the new sequencer agent template.
    event SequencerAgentTemplateSet(address indexed oldValue, address indexed newValue);

    /// @notice Emits when the L2 gas limit is set.
    /// @param oldValue The old L2 gas limit.        
    event L2GasSet(uint32 oldValue, uint32 newValue);

    /// @notice Emits when withdrawRewards is set.
    /// @param oldValue The old withdrawRewards.
    /// @param newValue The new withdrawRewards.
    event WithdrawRewardsSet(bool oldValue, bool newValue);

    /// @notice The template contract for sequencer agents.
    address public sequencerAgentTemplate;

    /// @notice The Metis token.
    IERC20 public metis;

    /// @notice The LockingPool contract address.
    ILockingPool public lockingPool;

    /// @notice The LockingInfo contract address.
    ILockingInfo public lockingInfo;

    /// @notice The L2 messenger contract.
    ICrossDomainMessenger public messenger;

    /// @notice The ID of the L2 chain.
    uint256 public l2ChainId;

    /// @notice The address of the L2 MetisMinter contract.
    address public l2Minter;

    /// @notice The address of the L2 RewardDispatcher contract.
    address public l2RewardDispatcher;

    /// @notice The list of sequencer agents.
    mapping(uint32 => address) public sequencerAgents;

    /// @notice The number of sequencer agents.
    uint32 public sequencerAgentCount;

    /// @notice The list of active sequencer agent IDs.
    uint32[] public activeSequencerIds;

    /// @notice The sum of rewards of all sequencers.
    uint256 public sumRewards;

    /// @notice L2 gas limit.
    uint32 public l2Gas;

    /// @notice withdraw rewards
    bool public withdrawRewards;

    /// @notice Initializes the contract.
    function initialize( 
        address _metis, 
        address _lockingPool, 
        address _l1Bridge, 
        uint256 _l2ChainId, 
        uint32 _l2Gas, 
        address _l2Minter, 
        address _l2RewardDispatcher
        ) public initializer {
        require( _metis != address(0) && _lockingPool != address(0) && _l1Bridge != address(0) && _l2Minter != address(0) && _l2RewardDispatcher != address(0), "Dealer: zero address");
        __Ownable_init(msg.sender);
        metis = IERC20(_metis);
        lockingPool = ILockingPool(_lockingPool);
        lockingInfo = lockingPool.escrow();
        messenger = ICrossDomainMessenger(ICrossDomainEnabled(_l1Bridge).messenger());
        l2ChainId = _l2ChainId;
        l2Gas = _l2Gas;
        l2Minter = _l2Minter;
        l2RewardDispatcher = _l2RewardDispatcher;

    }

    /// @notice Returns the number of active sequencers.
    /// @return The number of active sequencers.
    function activeSequencerCount() external view returns (uint32) {
        return uint32(activeSequencerIds.length);
    }

    /// @notice set withdraw rewards
    /// @param _withdrawRewards The new value of the withdrawRewards flag.
    function setWithdrawRewards(bool _withdrawRewards) external onlyOwner {
        bool _old = withdrawRewards;
        withdrawRewards = _withdrawRewards;
        emit WithdrawRewardsSet(_old, _withdrawRewards);
    }

    /// @notice Adds a new sequencer agent.
    /// @return The index of the new sequencer agent.
    function addAgent() external onlyOwner returns (uint32) {
        bytes memory data = abi.encodeWithSelector(SequencerAgent.initialize.selector, address(this), lockingPool, lockingInfo, address(metis));
        address clone = address(new BeaconProxy(address(this), data));
        uint32 index = sequencerAgentCount;
        sequencerAgents[index] = clone;
        emit SequencerAgentAdded(index, clone);
        sequencerAgentCount++;
        return index;
    }

    /// @notice Locks Metis tokens for a new sequencer.
    /// @param agentId The index of the sequencer agent.
    /// @param sequencerSigner The address of the sequencer signer.
    /// @param amount The amount of Metis tokens to lock.
    /// @param signerPubKey The public key of the sequencer signer.
    function lockFor(uint32 agentId, address sequencerSigner, uint256 amount, bytes memory signerPubKey) external onlyOwner {
        address agent = sequencerAgents[agentId];
        IERC20(metis).transferFrom(msg.sender, agent, amount);
        SequencerAgent(agent).lock(sequencerSigner, l2Minter, amount, signerPubKey);
        _setActive(agentId, true);
    }

    /// @notice Unlock Metis tokens and terminate the sequencer.
    /// @param agentId The index of the sequencer agent.
    function unlock(uint32 agentId) external payable onlyOwner {
        SequencerAgent(sequencerAgents[agentId]).unlock(l2Gas);
        _removeFromActiveList(agentId);
    }

    /// @notice The `unlockClaim` function allows a sequencer to claim their Metis tokens after the unlocking waiting period has elapsed.
    /// @param agentId The index of the sequencer agent.
    function unlockClaim(uint32 agentId) external payable onlyOwner {
        SequencerAgent(sequencerAgents[agentId]).unlockClaim(l2Gas);
    }

    /// @notice Facilitates the process of augmenting the locked Metis tokens and rewards for all currently active sequencers.
    /// @dev The `relock` function will transfer Metis tokens from the Dealer contract to the sequencer agent contract, and then call the `relock` function on the sequencer agent contract.
    /// @return totalProcessed The total amount of Metis tokens and rewards that have been relocked.
    function relock() external payable returns (uint256 totalProcessed) {
        require(activeSequencerIds.length > 0, "Dealer: no active sequencer");

        uint maxLock = lockingInfo.maxLock();
        uint256 undistributedAmount = metis.balanceOf(address(this));
        uint256 totalRewards = 0;

        for (uint32 i = 0; i < activeSequencerIds.length; i++) {
            uint32 agentId = activeSequencerIds[i];
            SequencerAgent agent = SequencerAgent(sequencerAgents[agentId]);
            ILockingPool.SequencerData memory seq = agent.sequencerData();
            (uint256 reward, uint256 locked) = (seq.reward, seq.amount);
            totalRewards += reward;

            // The lock quota means the amount of Metis tokens that can be locked for the sequencer, due to the maximum lock amount.
            uint256 lockQuota = locked < maxLock ? maxLock - locked : 0;

            // The amount of Metis tokens that can be locked is the minimum of the lock quota and the undistributed amount.
            uint256 lockAmount = Math.min(lockQuota, undistributedAmount);

            // The undistributed amount should be reduced by the amount of Metis tokens that have been locked.
            undistributedAmount -= lockAmount;

            // If there is not any lock amount or reward, the process should be skipped.
            uint256 toBeProcessed = lockAmount + reward;
            if (toBeProcessed == 0) {
                continue;
            }

            totalProcessed += toBeProcessed;

            // The rewards are withdrawn if the `withdrawRewards` flag is set to true, or if the locked amount plus the amount to be processed exceeds the maximum lock amount.
            bool _withdrawRewards = withdrawRewards || locked + toBeProcessed > maxLock;
            if (_withdrawRewards && reward > 0) {
                agent.withdrawRewards(l2Gas);
            }

            // If the lock amount is not zero, or if we decided to convert the rewards to lock amount, the `relock` function is called.
            if (!_withdrawRewards || lockAmount > 0) {
                IERC20(metis).transfer(address(agent), lockAmount);
                agent.relock(lockAmount);
                emit SequencerRelocked(agentId, lockAmount, reward);
            }
        }

        // In the event of any rewards, the MetisMinter contract on Layer 2 is invoked to mint eMetis tokens. These tokens are then distributed as rewards to seMetis holders.
        if (totalRewards > 0) {
            _mintL2EMetis(totalRewards);
            sumRewards += totalRewards;
        }
    }

    /// @notice Sets the active status of a sequencer agent.
    function setActive(uint32 agentId, bool active) external onlyOwner {
        _setActive(agentId, active);
    }

    /// @notice Sets the sequencer agent template.
    /// @param _sequencerAgentTemplate The address of the new sequencer agent template.
    function setSequencerAgentTemplate(address _sequencerAgentTemplate) external onlyOwner {
        require(_sequencerAgentTemplate != address(0), "Dealer: zero address");
        sequencerAgentTemplate = _sequencerAgentTemplate;
    }

    /// @notice Sets the L2 gas limit.
    /// @param _l2Gas The new L2 gas limit.
    /// @dev The L2 gas limit is used when minting eMetis tokens on Layer 2.
    function setL2Gas(uint32 _l2Gas) external onlyOwner {
        uint32 _old = l2Gas;
        l2Gas = _l2Gas;
        emit L2GasSet(_old, _l2Gas);
    }

    /// @notice Returns the total amount of Metis tokens that have been locked for all sequencers.
    function totalLocked() external view returns (uint256) {
        uint256 total = 0;
        for (uint32 i = 0; i < activeSequencerIds.length; i++) {
            uint32 agentId = activeSequencerIds[i];
            SequencerAgent agent = SequencerAgent(sequencerAgents[agentId]);
            uint256 locked = agent.sequencerData().amount;
            total += locked;
        }
        return total;
    }

    /// @notice Use Dealer as a beacon of BeaconProxy for SequencerAgent
    /// @return The implementation address
    function implementation() external view returns (address) {
        return sequencerAgentTemplate;
    }

    /// @notice Sets the active status of a sequencer agent.
    function _setActive(uint32 agentId, bool active) internal {
        if (active) {
            for (uint32 i = 0; i < activeSequencerIds.length; i++) {
                require(activeSequencerIds[i] != agentId, "Dealer: already active");
            }
            activeSequencerIds.push(agentId);
        } else {
            _removeFromActiveList(agentId);
        }
    }

    /// @notice mint veMetis on Layer 2
    /// @param amount Metis amount
    function _mintL2EMetis(uint256 amount) internal {
        bytes memory message = abi.encodeWithSelector(IVeMetisMinter.mintFromL1.selector, amount);
        messenger.sendMessageViaChainId{value:msg.value}(l2ChainId, l2Minter, message, l2Gas);
        emit L2MetisMinted(amount);
    }

    /// @notice Removes a sequencer agent from the active list.
    /// @param agentId The index of the sequencer agent.
    /// @dev The sequencer agent is removed from the active list by swapping it with the last element in the list, and then popping the last element.
    function _removeFromActiveList(uint32 agentId) internal returns (uint32 index) {
        index = _findFromActiveList(agentId);
        require(index < type(uint32).max, "Dealer: not active");
        activeSequencerIds[index] = activeSequencerIds[activeSequencerIds.length - 1];
        activeSequencerIds.pop();
    }

    /// @notice Finds the index of a sequencer agent in the active list.
    /// @param agentId The index of the sequencer agent.
    /// @return The index of the sequencer agent in the active list.
    function _findFromActiveList(uint32 agentId) internal view returns (uint32) {
        for (uint32 index = 0; index < activeSequencerIds.length; index++) {
            if (activeSequencerIds[index] == agentId) {
                return index;
            }
        }
        return type(uint32).max;
    }
}