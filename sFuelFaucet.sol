// SPDX-License-Identifier: NONE

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract sFuelFaucet is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address sFuelFaucets;
    
    bytes32 internal constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    uint256 private Amount = 0.0001 ether;
    
    event Payed(address indexed payee, uint256 indexed amount, uint256 indexed timestamp);

    constructor() payable {
        _grantRole(MANAGER_ROLE, msg.sender);
        sFuelFaucets = address(this);
    }

    function GetBalance(address payable receiver) public view returns (uint256) {
        return receiver.balance;
    }

    function Pay(address payable receiver) external payable nonReentrant {
        require(GetBalance(payable(_msgSender())) == 0, "sFuelFaucet: Caller must have no sFuel");
        require(GetBalance(payable(sFuelFaucets)) >= Amount, "sFuelFaucet: Contract Empty");

        uint256 _receiverBalance = receiver.balance;
        if (_receiverBalance < Amount) {
            uint256 _payableAmount = Amount - _receiverBalance;
            receiver.transfer(_payableAmount);
            emit Payed(receiver, _payableAmount, block.timestamp);
        }
    }

    function Depo() external payable onlyRole(MANAGER_ROLE) {
        require(_msgSender().balance > msg.value, "insuficient Balance");

        (bool sent, bytes memory data) = payable(sFuelFaucets).call{value: msg.value}("");
    }

    function UpdateAmount(uint256 newamount) external payable onlyRole(MANAGER_ROLE) {
        require(newamount > 0, "sFuelFaucet: Invalid Amount");
        Amount = newamount;
    }

    function SetManager(address newmanager) external payable onlyRole(MANAGER_ROLE) {
        _grantRole(MANAGER_ROLE, newmanager);
        _revokeRole(MANAGER_ROLE, _msgSender());
    }

    function StuckTokens(address token) external payable onlyRole(MANAGER_ROLE) {
        if (token == address(0x0)) {
            payable(_msgSender()).transfer(address(this).balance);
            return;
        }
        IERC20 _stucktoken = IERC20(token);
        _stucktoken.safeTransfer(_msgSender(), _stucktoken.balanceOf(sFuelFaucets));
    }
}