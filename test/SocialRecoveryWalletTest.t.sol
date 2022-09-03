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

    receive() external payable {}
}
