//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IVeMetisMinter {
    function mint(address user, uint256 amount) external;

    function mintFromL1(uint256 amount) external;

    function stake(uint256 amount) external payable;
}
