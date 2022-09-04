// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "src/SocialRecoveryWallet.sol";


contract SocialRecoveryWalletTest is Test {
    SocialRecoveryWallet wallet;
    function setUp() public {
        wallet = new SocialRecoveryWallet(0);
    }

    function testPositive() public {
        
        address alice = address(1);
        vm.deal(alice, 10 ether);
        vm.startPrank(alice);
        uint256 balance_before=address(this).balance;
        payable(address(wallet)).transfer(2 ether);
        assertEq(address(wallet).balance, 2 ether);
        vm.stopPrank();
        wallet.withdraw(1 ether);
        uint256 balance_after=address(this).balance;
        assertEq(balance_after, balance_before+1 ether);
        assertEq(address(wallet).balance, 1 ether);
    }

    function testNowOwner() public {

        payable(address(wallet)).transfer(2 ether);
        address alice = address(1);
        vm.deal(alice, 10 ether);
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(NotOwner.selector, address(alice)));
        wallet.withdraw(1 ether);
    }

    function testInsufficientBalance() public {

        assertEq(address(wallet).balance,0);
        vm.expectRevert(abi.encodeWithSelector(InsufficientBalance.selector, 0, 1 ether));
        wallet.withdraw(1 ether);
    }

    function testSetGuardian() public {
        address alice = vm.addr(1);
        address bob = vm.addr(2);
        address[] memory guardians = new address[](2);
        guardians[0]=alice;
        guardians[1]=bob;
        bytes32 g1 = vm.load(address(wallet), bytes32(uint256(1)));
        bytes32 g2 = vm.load(address(wallet), bytes32(uint256(2)));
        assertEq(address(0), address(uint160(uint256(g1))));
        assertEq(address(0), address(uint160(uint256(g2))));

        wallet.setGuardians(guardians);
        g1 = vm.load(address(wallet), bytes32(uint256(1)));
        g2 = vm.load(address(wallet), bytes32(uint256(2)));

        assertEq(alice, address(uint160(uint256(g1))));
        assertEq(bob, address(uint160(uint256(g2))));


    }

    function testSetGuardian1() public {
        address alice = vm.addr(1);
        address[] memory guardians = new address[](1);
        guardians[0]=alice;
        vm.expectRevert(InvalidGuardianInitialization.selector);
        wallet.setGuardians(guardians);
       


    }

    function testSetGuardian3() public {
        address alice = vm.addr(1);
        address[] memory guardians = new address[](3);
        guardians[0]=alice;
        guardians[1]=vm.addr(2);
        guardians[2]=vm.addr(3);
        vm.expectRevert(InvalidGuardianInitialization.selector);
        wallet.setGuardians(guardians);
       


    }

    function testSetNewOwnerWithoutGuardianSet() public {



        address carol = vm.addr(3);

        uint256 nonce = wallet.getNonce();
        bytes32 msgHash= keccak256(abi.encodePacked(carol, nonce));
        bytes32 ethMsgHash = keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes1 v_byte;
        (v,r,s) = vm.sign(1,ethMsgHash);
        v_byte = bytes1(v);
        bytes memory signature_1 = bytes.concat(r,s,v_byte);
        (v,r,s) = vm.sign(2,ethMsgHash);
        v_byte = bytes1(v);
        bytes memory signature_2 = bytes.concat(r,s,v_byte);
        vm.expectRevert("Guardians not set");
        wallet.setNewOwner(carol, nonce, signature_1, signature_2);

    }

    function testSetNewOwner() public {

        address alice = vm.addr(1);
        address bob = vm.addr(2);

        address carol = vm.addr(3);
        address dave=vm.addr(4);

        uint256 nonce = wallet.getNonce();

        //calculate message hash
        bytes32 msgHash= keccak256(abi.encodePacked(carol, nonce));
        bytes32 ethMsgHash = keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes1 v_byte;
        //msg sign by alice
        (v,r,s) = vm.sign(1,ethMsgHash);
        v_byte = bytes1(v);
        bytes memory signature_1 = bytes.concat(r,s,v_byte);
        //msg sign by bob
        (v,r,s) = vm.sign(2,ethMsgHash);
        v_byte = bytes1(v);
        bytes memory signature_2 = bytes.concat(r,s,v_byte);
        
        //set alice and bob as the guardians
        address[] memory guardians = new address[](2);
        guardians[0]=alice;
        guardians[1]=bob;

        wallet.setGuardians(guardians);
        //anybody can send the message to setNewOwner - hence sending through dave
        vm.startPrank(dave);

        assertEq(wallet.proposedOwner(),address(0));
        assertEq(wallet.proposalTimestamp(),0);
        wallet.setNewOwner(carol, nonce, signature_1, signature_2);
        assertEq(wallet.proposedOwner(),carol);
        assertEq(wallet.proposalTimestamp(),block.timestamp);
        assertEq(wallet.getNonce(),nonce+1);

    }

    function setupAndSignMsg() private returns(address, uint256, bytes memory, bytes memory) {

        
       

        address carol = vm.addr(3);
       

        uint256 nonce = wallet.getNonce();

        //calculate message hash
        bytes32 msgHash= keccak256(abi.encodePacked(carol, nonce));
        bytes32 ethMsgHash = keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes1 v_byte;
        //msg sign by alice
        (v,r,s) = vm.sign(1,ethMsgHash);
        v_byte = bytes1(v);
        bytes memory signature_1 = bytes.concat(r,s,v_byte);
        //msg sign by bob
        (v,r,s) = vm.sign(2,ethMsgHash);
        v_byte = bytes1(v);
        bytes memory signature_2 = bytes.concat(r,s,v_byte);
        
        //set alice and bob as the guardians
        address[] memory guardians = new address[](2);
        guardians[0]=vm.addr(1);
        guardians[1]=vm.addr(2);

        wallet.setGuardians(guardians);
        return (carol,nonce, signature_1,signature_2);

    }

    function testSetNewOwnerInvalidProposal() public {

        ( , uint256 nonce, bytes memory signature_1, bytes memory signature_2) = setupAndSignMsg();
        address dave=vm.addr(4);
        //anybody can send the message to setNewOwner - hence sending through dave
        vm.startPrank(dave);
        vm.expectRevert("Invalid proposal");
        wallet.setNewOwner(address(0), nonce, signature_1, signature_2);

    }

    function testSetNewOwnerInvalidNonce() public {

        (address carol,uint256 nonce, bytes memory signature_1, bytes memory signature_2) = setupAndSignMsg();
        address dave=vm.addr(4);
        //anybody can send the message to setNewOwner - hence sending through dave
        vm.startPrank(dave);
        vm.expectRevert("Invalid proposal nonce");
        wallet.setNewOwner(carol, nonce+1, signature_1, signature_2);

    }

    function testFinalizeOwner() public {

        address alice = vm.addr(1);
        address bob = vm.addr(2);

        address carol = vm.addr(3);
        address dave=vm.addr(4);

        uint256 nonce = wallet.getNonce();

        //calculate message hash
        bytes32 msgHash= keccak256(abi.encodePacked(carol, nonce));
        bytes32 ethMsgHash = keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes1 v_byte;
        //msg sign by alice
        (v,r,s) = vm.sign(1,ethMsgHash);
        v_byte = bytes1(v);
        bytes memory signature_1 = bytes.concat(r,s,v_byte);
        //msg sign by bob
        (v,r,s) = vm.sign(2,ethMsgHash);
        v_byte = bytes1(v);
        bytes memory signature_2 = bytes.concat(r,s,v_byte);
        
        //set alice and bob as the guardians
        address[] memory guardians = new address[](2);
        guardians[0]=alice;
        guardians[1]=bob;
        wallet.changeWaitingPeriod(100);
        wallet.setGuardians(guardians);
        //anybody can send the message to setNewOwner - hence sending through dave
        vm.startPrank(dave);
        assertEq(wallet.owner(),address(this));      
        wallet.setNewOwner(carol, nonce, signature_1, signature_2);
        
        skip(100);
        assertEq(wallet.owner(),address(this));      
        wallet.finalizeNewOwner(carol);  
        assertEq(wallet.owner(),carol);      

    }

    function testInvalidProposalFinalize() public {

        (address carol,uint256 nonce, bytes memory signature_1, bytes memory signature_2) = setupAndSignMsg();
        address dave=vm.addr(4);
        wallet.changeWaitingPeriod(100);
        //anybody can send the message to setNewOwner - hence sending through dave
        vm.startPrank(dave);
        
        wallet.setNewOwner(carol, nonce, signature_1, signature_2);
        
        skip(100);
        vm.expectRevert("Invalid proposal");
        wallet.finalizeNewOwner(dave);     
    }

    function testNoActiveProposalFinalize() public {

        (address carol,uint256 nonce, bytes memory signature_1, bytes memory signature_2) = setupAndSignMsg();
        address dave=vm.addr(4);
        wallet.changeWaitingPeriod(100);
        //anybody can send the message to setNewOwner - hence sending through dave
        vm.startPrank(dave);
        
        //wallet.setNewOwner(carol, nonce, signature_1, signature_2);
        
        skip(100);
        vm.expectRevert("No proposal active");
        wallet.finalizeNewOwner(carol);     
    }

    function testWaitingPeriodNotOver() public {

        (address carol,uint256 nonce, bytes memory signature_1, bytes memory signature_2) = setupAndSignMsg();
        address dave=vm.addr(4);
        wallet.changeWaitingPeriod(100);
        //anybody can send the message to setNewOwner - hence sending through dave
        vm.startPrank(dave);
        
        wallet.setNewOwner(carol, nonce, signature_1, signature_2);
        
        skip(50);
        vm.expectRevert("Waiting period not over");
        wallet.finalizeNewOwner(carol); 
    }

    function testRevertProposal() public {

        (address carol,uint256 nonce, bytes memory signature_1, bytes memory signature_2) = setupAndSignMsg();
        address dave=vm.addr(4);
        wallet.changeWaitingPeriod(100);
        //anybody can send the message to setNewOwner - hence sending through dave
        vm.startPrank(dave);
        
        wallet.setNewOwner(carol, nonce, signature_1, signature_2);
        
        skip(100);
        //vm.expectRevert("Waiting period not over");
        vm.stopPrank();
        assertEq(wallet.proposedOwner(),carol);
        assertEq(wallet.proposalTimestamp(),block.timestamp-100);
        wallet.revertProposal(); 
        assertEq(wallet.proposedOwner(),address(0));
        assertEq(wallet.proposalTimestamp(),0);

        vm.expectRevert("No proposal active");
        wallet.finalizeNewOwner(carol); 
        assertEq(wallet.owner(),address(this));

    }
    
    receive() external payable {}
}

// set guardian positive flow
// set guardian negative flow
// set new owner - correct signature
// set new owner - incorrect signature
// set new owner - incorrect owner address / nonce
// finalize owner - incorrect proposedOwner
// finalize owner - before waitingPeriod
// finalize owner - correct flow
// revert ownership
// set owner called before waiting period over
