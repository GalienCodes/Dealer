// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
// import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
// import "../interface/ICrossDomainEnabled.sol";


// contract L1Config is ContextUpgradeable, IBeacon {
//     address public sequencerAgentTemplate;
//     address public metis;
//     address public lockingPool;
//     address public l1Bridge;
//     uint256 public l2ChainId;
//     uint32 public l2Gas;
//     address public l2Minter;
//     address public messenger;
//     address public owner;

//     modifier onlyOwner() {
//         require(owner == address(0) || _msgSender() == owner, "L1Config: caller is not the owner");
//         _;
//     }

//     function initialize(address _sequencerAgentTemplate, address _metis, address _lockingPool, address _l1Bridge, uint256 _l2ChainId, uint32 _l2Gas, address _l2Minter) public initializer {
//         sequencerAgentTemplate = _sequencerAgentTemplate;
//         metis = _metis;
//         lockingPool = _lockingPool;
//         l1Bridge = _l1Bridge;
//         messenger = ICrossDomainEnabled(_l1Bridge).messenger();
//         l2ChainId = _l2ChainId;
//         l2Gas = _l2Gas;
//         l2Minter = _l2Minter;
//         owner = _msgSender();
//     }

//     /**
//      * @notice IBeacon interface for SequencerAgentProxy
//      * @return The implementation address
//      */
//     function implementation() external view override returns (address) {
//         return sequencerAgentTemplate;
//     }

//     function updateSequencerAgentTemplate(address _sequencerAgentTemplate) external onlyOwner {
//         sequencerAgentTemplate = _sequencerAgentTemplate;
//     }

//     function transferOwnership(address _owner) external onlyOwner {
//         require(_owner != address(0), "L1Config: zero address");
//         owner = _owner;
//     }
// }