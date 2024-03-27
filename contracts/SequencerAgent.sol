// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interface/ICrossDomainEnabled.sol";
import "./interface/ILockingPool.sol";
import "./interface/IVeMetisMinter.sol";
import "./L1Config.sol";

contract SequencerAgent is ContextUpgradeable, AccessControlUpgradeable {
    address private owner;
    address public dealer;
    L1Config public config;
    ILockingPool public lockingPool;
    IERC20 public metis;
    uint256 public sequencerId;
    address public sequencerSigner;
    bool public active;

    modifier onlyDealer() {
        require(msg.sender == dealer, "SequencerAgent: only dealer");
        _;
    }

    function initialize(
        address _lockingPool,
        address _metis
    ) external initializer {
        lockingPool = ILockingPool(_lockingPool);
        metis = IERC20(_metis);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // set dealer contract address
    function setDealerAddress(
        address _dealer
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        dealer = _dealer;
    }

    function locked() public view returns (uint256) {
        return lockingPool.sequencerLock(sequencerId);
    }

    function lockFor(
        address _sequencerSigner,
        uint256 _amount,
        bytes memory _signerPubKey
    ) public onlyDealer {
        require(sequencerId == 0, "SequencerAgent: sequencer already locked");
        require(_sequencerSigner != address(0), "SequencerAgent: zero address");
        require(_amount > 0, "SequencerAgent: zero amount");

        sequencerSigner = _sequencerSigner;
        metis.approve(address(lockingPool), _amount);
        lockingPool.lockFor(sequencerSigner, _amount, _signerPubKey);
        sequencerId = lockingPool.getSequencerId(sequencerSigner);
        active = true;
    }

    function relock() public onlyDealer returns (uint256 reward) {
        reward = ILockingPool(lockingPool).sequencerReward(sequencerId);
        uint amount = IERC20(metis).balanceOf(address(this));
        metis.approve(address(lockingPool), amount);
        ILockingPool(lockingPool).relock(sequencerId, amount, true);
    }

    function unlock() public onlyDealer {
        lockingPool.unlock(sequencerId);
        active = false;
    }

    function unlockClaim() public onlyDealer {
        lockingPool.unlockClaim(sequencerId);
        IERC20(metis).transfer(dealer, IERC20(metis).balanceOf(address(this)));
    }
}
