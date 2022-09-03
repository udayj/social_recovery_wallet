// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "Errors.sol";
import "VerifySignature.sol";

contract SocialRecoveryWallet {
    address payable public owner;
    address guardian_1;
    address guardian_2;
    address public proposedOwner;
    uint256 public proposalTimestamp;
    uint256 waitingPeriod;
    uint256 nonce;
    VerifySignature sigVerifier;

    receive() external payable {}

    constructor(uint _waitingPeriod) {
        owner = payable(msg.sender);
        sigVerifier = new VerifySignature();
        waitingPeriod = _waitingPeriod;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner(msg.sender);
        }
        _;
    }

    function getNonce() external view returns (uint256) {
        return nonce;
    }

    function withdraw(uint256 amount) public onlyOwner {
        if (address(this).balance < amount) {
            revert InsufficientBalance(address(this).balance, amount);
        }

        owner.transfer(amount);
    }

    function setGuardians(address[] memory guardians) public onlyOwner {
        if (
            guardians.length != 2
        ) {
            revert InvalidGuardianInitialization();
        }

        guardian_1 = guardians[0];
        guardian_2 = guardians[1];
    }

    // this function can be called to initiate a new proposal for ownership change
    function setNewOwner(
        address _proposedOwner,
        uint256 _nonce,
        bytes calldata signature_1,
        bytes calldata signature_2
    ) external {

        require (guardian_1!= address(0) && guardian_2!=address(0), "Guardians not set");
        require (_proposedOwner != address(0), "Invalid proposal");
        require (_nonce == nonce, "Invalid proposal nonce");

        bool isVerifiedGuardian1=sigVerifier.verify(guardian_1, _proposedOwner, _nonce, signature_1);
        bool isVerifiedGuardian2=sigVerifier.verify(guardian_1, _proposedOwner, _nonce, signature_2);
        if (!isVerifiedGuardian1 || !isVerifiedGuardian2) {
            revert InvalidGuardianSignature();
        }
        nonce = nonce + 1;
        proposedOwner=_proposedOwner;

        proposalTimestamp = block.timestamp;

    }

    // this function can be called after waitingPeriod time has elapsed since proposal
    function finalizeNewOwner(
        address _proposedOwner
    ) external {

        require (proposalTimestamp!=0, "No proposal active");
        require (_proposedOwner == proposedOwner, "Invalid proposal");
        require (block.timestamp >= proposalTimestamp + waitingPeriod, "Waiting period not over");
        proposalTimestamp=0;
        owner = payable(_proposedOwner);
        proposedOwner = address(0);
        
    }

    // this function can be used to revert a proposal provided it has not been finalised
    function revertProposal() external onlyOwner {

        require (proposalTimestamp!=0, "No proposal active");
        proposalTimestamp=0;
        proposedOwner = address(0);
    }

    function changeWaitingPeriod(uint256 _waitingPeriod) external onlyOwner {

        require (proposalTimestamp==0, "Proposal already active");
        waitingPeriod = _waitingPeriod;
        
    }

    //have 2 guardians, if message (change owner) is signed by guardians then reset ownership (use nonce to avoid replay)
    //allow owner to change guardians
    // make timelocked ownership change (guardians can change ownership but 2 transactions are needed with time gap)
    // current owner can revert change of ownership initiated by guardians
}
