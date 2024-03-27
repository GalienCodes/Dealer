// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title ICrossDomainMessenger
 */
interface ICrossDomainMessenger {
    /**********
     * Events *
     **********/

    event SentMessage(
        address indexed target,
        address sender,
        bytes message,
        uint256 messageNonce,
        uint256 gasLimit,
        uint256 chainId
    );
    event RelayedMessage(bytes32 indexed msgHash);
    event FailedRelayedMessage(bytes32 indexed msgHash);

    /*************
     * Variables *
     *************/

    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/
    
    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external payable;


    /**
     * Sends a cross domain message to the target messenger.
     * @param _chainId L2 chain id.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessageViaChainId(
        uint256 _chainId,
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external payable;

    function replayMessageViaChainId(
        uint256 _chainId,
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _queueIndex,
        uint32 _oldGasLimit,
        uint32 _newGasLimit
    )external;
}