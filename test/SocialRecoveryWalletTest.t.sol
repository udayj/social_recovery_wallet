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
