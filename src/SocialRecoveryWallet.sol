// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "Errors.sol";

contract SocialRecoveryWallet {

    address payable public owner;
    address guardian_1;
    address guardian_2;
    
    receive() external payable {}

    constructor () {
        owner = payable(msg.sender);

    }

    modifier onlyOwner (address caller) {

        if (msg.sender!=owner) {
            revert NotOwner(msg.sender);
        }
        _;
    }
    function withdraw(uint256 amount) public onlyOwner {

    
        if(address(this).balance < amount) {
            revert InsufficientBalance(address(this).balance, amount);
        }

        owner.transfer(amount);
    }

    function setGuardians(address[] memory guardians) public onlyOwner {

        if (guardians.length !=2 || guardians[0]==address(0) || guardians[1]==address(0)) {
            revert InvalidGuardians();
        }

        guardian_1=guardians[0];
        guardian_2=guardians[1];
    }

    
    //have 2 guardians, if message (change owner) is signed by guardians then reset ownership (use nonce to avoid replay)
    //allow owner to change guardians
    // make timelocked ownership change (guardians can change ownership but 2 transactions are needed with time gap)
    // current owner can revert change of ownership initiated by guardians
}
