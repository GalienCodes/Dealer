// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interface/ICrossDomainEnabled.sol";
import "./interface/ILockingPool.sol";
import "./interface/IVeMetisMinter.sol";
import "./interface/ICrossDomainMessenger.sol";
import "./L1Config.sol";
import "./SequencerAgent.sol";

contract Dealer is AccessControlUpgradeable {
    event SequencerAgentAdded(uint32 index, address agent);
    event SequencerRelocked(uint32 index, uint256 amount, uint256 reward);
    event L2MetisMinted(bool principal, uint256 amount);

    uint256 public constant RELOCK_RESERVE = 0.01 ether;

    L1Config public config;
    address public sequencerAgentTemplate;
    address public metis;
    address public lockingPool;
    address public messenger;
    uint256 public l2ChainId;
    address public l2Minter;
    uint32 public l2Gas;
    mapping(uint32 => address) public sequencerAgents;
    uint32 public sequencerAgentCount;
    uint32 public __reserved;
    uint32[] public activeSequencerIds;
    uint256 public sumRewards;

    function initialize(address _config) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        config = L1Config(_config);
        metis = config.metis();
        lockingPool = config.lockingPool();
        messenger = ICrossDomainEnabled(config.l1Bridge()).messenger();
        l2ChainId = config.l2ChainId();
        l2Minter = config.l2Minter();
        l2Gas = config.l2Gas();
    }

    function activeSequencerCount() external view returns (uint32) {
        return uint32(activeSequencerIds.length);
    }

    function addAgent() external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint32) {
        bytes memory data = abi.encodeWithSelector(SequencerAgent.initialize.selector, address(this), lockingPool, metis);
        address clone = address(new BeaconProxy(address(config), data));
        uint32 index = sequencerAgentCount;
        sequencerAgents[index] = clone;
        emit SequencerAgentAdded(index, clone);
        sequencerAgentCount++;
        return index;
    }

    function lockFor(uint32 agentId, address sequencerSigner, uint256 amount, bytes memory signerPubKey) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address agent = sequencerAgents[agentId];
        IERC20(metis).transferFrom(msg.sender, agent, amount);
        SequencerAgent(agent).lockFor(sequencerSigner, amount, signerPubKey);
        _mintL2EMetis(amount, true);
        activeSequencerIds.push(agentId);
    }

    function unlock(uint32 agentId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        SequencerAgent(sequencerAgents[agentId]).unlock();
        _removeFromActiveList(agentId);
    }

    function unlockClaim(uint32 agentId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        SequencerAgent(sequencerAgents[agentId]).unlockClaim();
    }

    function getLeastLockedSequencerAgentId() public view returns (uint32 ret, uint256 leastLockedAmount) {
        require(activeSequencerIds.length > 0, "Dealer: no sequencer");

        leastLockedAmount = type(uint256).max;
        for (uint32 i = 0; i < activeSequencerIds.length; i++) {
            uint32 agentId = activeSequencerIds[i];
            SequencerAgent agent = SequencerAgent(sequencerAgents[agentId]);
            uint256 lockedAmount = agent.locked();
            if (lockedAmount > 0 && lockedAmount < leastLockedAmount) {
                leastLockedAmount = lockedAmount;
                ret = agentId;
            }
        }

        require(leastLockedAmount < type(uint256).max, "Dealer: no active sequencer");
    }

    function relock() external payable {
        require(activeSequencerIds.length > 0, "Dealer: no active sequencer");
        uint256 balance = IERC20(metis).balanceOf(address(this));
        require(balance >= activeSequencerIds.length, "Dealer: no Metis to relock");

        // If the balance is greater than the relock reserve, relock most of balance to the sequencer with the least locked tokens.
        // Otherwise, relock minimum amount to all active sequencers.
        (uint32 leastLockedSequencerAgentId,) = balance > RELOCK_RESERVE ? getLeastLockedSequencerAgentId() : (type(uint32).max, 0);

        // relock for all active sequencers
        uint256 totalRewards = 0;
        for (uint32 i = 0; i < activeSequencerIds.length; i++) {
            uint32 agentId = activeSequencerIds[i];
            SequencerAgent agent = SequencerAgent(sequencerAgents[agentId]);
            // Stake Metis tokens to the sequencer with the least locked tokens. 
            // For other sequencers, just lock rewards.
            // However, a zero amount isn't permitted, so we set it to 1.
            uint256 amount = agentId == leastLockedSequencerAgentId ? balance - RELOCK_RESERVE - activeSequencerIds.length + 1 : 1;
            IERC20(metis).transfer(address(agent), amount);
            uint256 reward = agent.relock();
            totalRewards += reward;
            emit SequencerRelocked(agentId, amount, reward);
        }

        require(totalRewards > 0 || balance > RELOCK_RESERVE, "Dealer: no rewards and no Metis to relock");

        _mintL2EMetis(totalRewards, false);
        sumRewards += totalRewards;
    }

    function setActive(uint32 agentId, bool active) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (active) {
            activeSequencerIds.push(agentId);
        } else {
            _removeFromActiveList(agentId);
        }
    }

    function totalLocked() external view returns (uint256) {
        uint256 total = 0;
        for (uint32 i = 0; i < activeSequencerIds.length; i++) {
            uint32 agentId = activeSequencerIds[i];
            SequencerAgent agent = SequencerAgent(sequencerAgents[agentId]);
            total += agent.locked();
        }
        return total;
    }

    function _mintL2EMetis(uint256 amount, bool principal) internal {
        bytes memory message = abi.encodeWithSelector(IVeMetisMinter.mintFromL1.selector, amount, principal);
        ICrossDomainMessenger(messenger).sendMessageViaChainId{value:msg.value}(l2ChainId, l2Minter, message, l2Gas);
        emit L2MetisMinted(principal, amount);
    }

    function _removeFromActiveList(uint32 agentId) internal returns (uint32 index) {
        index = _findFromActiveList(agentId);

        if (index != type(uint32).max) {
            activeSequencerIds[index] = activeSequencerIds[activeSequencerIds.length - 1];
            activeSequencerIds.pop();
        }
    }

    function _findFromActiveList(uint32 agentId) internal view returns (uint32) {
        for (uint32 index = 0; index < activeSequencerIds.length; index++) {
            if (activeSequencerIds[index] == agentId) {
                return index;
            }
        }
        return type(uint32).max;
    }
}