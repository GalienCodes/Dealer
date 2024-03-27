// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


interface ICrossDomainEnabled {
    function messenger() external view returns (address);
}