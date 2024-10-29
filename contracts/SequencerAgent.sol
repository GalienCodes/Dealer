// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/ILockingPool.sol";
import "../interface/ILockingInfo.sol";

contract SequencerAgent is ContextUpgradeable {
    address public dealer;
    ILockingPool public lockingPool;
    ILockingInfo public lockingInfo;
    IERC20 public metis;
    uint256 public sequencerId;
    address public sequencerSigner;
    bool public active;

    modifier onlyDealer() {
        require(msg.sender == dealer, "SequencerAgent: only dealer");
        _;
    }

    function initialize(address _dealer, ILockingPool _lockingPool, ILockingInfo _lockingInfo, address _metis) external initializer {
        dealer = _dealer;
        lockingPool = _lockingPool;
        lockingInfo = _lockingInfo;
        metis = IERC20(_metis);
    }

    function lock(address _sequencerSigner, address _rewardRecipient, uint256 _amount, bytes memory _signerPubKey) public onlyDealer {
        require(sequencerId == 0, "SequencerAgent: sequencer already locked");
        require(_sequencerSigner != address(0) && _rewardRecipient != address(0), "SequencerAgent: zero address");
        require(_amount > 0, "SequencerAgent: zero amount");

        sequencerSigner = _sequencerSigner;
        metis.approve(address(lockingInfo), type(uint256).max);
        lockingPool.lockWithRewardRecipient(sequencerSigner, _rewardRecipient, _amount, _signerPubKey);
        sequencerId = lockingPool.seqSigners(sequencerSigner);
        active = true;
    }

    function relock(uint256 amount) public onlyDealer {
        lockingPool.relock(sequencerId, amount, true);
    }

    function withdrawRewards(uint32 l2Gas) public onlyDealer {
        lockingPool.withdrawRewards(sequencerId, l2Gas);
    }

    function sequencerData() public view returns (ILockingPool.SequencerData memory) {
        return lockingPool.sequencers(sequencerId);
    }

    function unlock(uint32 l2Gas) public payable onlyDealer {
        lockingPool.unlock{value: msg.value}(sequencerId, l2Gas);
        active = false;
    }

    function unlockClaim(uint32 l2Gas) public payable onlyDealer {
        lockingPool.unlockClaim{value: msg.value}(sequencerId, l2Gas);
        IERC20(metis).transfer(dealer, IERC20(metis).balanceOf(address(this)));
    }
}