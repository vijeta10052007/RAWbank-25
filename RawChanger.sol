// SPDX-License-Identifier: NONE

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RawChanger is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address RawChangers;
    
    bytes32 internal constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct Ticket {
        string Code;
        string Symbol;
        uint256 Balance;
    }
    
    iRawBank iRawBanks;

    mapping(string => string) internal Officers;

    mapping(string => Ticket) internal Tickets;

    event TicketUpdate(Ticket result);

    constructor() payable {
        _grantRole(MANAGER_ROLE, msg.sender);
        RawChangers = address(this);
    }

    function RawExchange(string calldata code, string calldata uid, uint256 key, uint256 lock, uint256 amount) external nonReentrant {
        require(Tickets[code].Balance == 1, "Expired");
        
        receiverAssistant(Officers["exchanger"], Tickets[code].Symbol, uid, key, lock, amount);
        emit TicketUpdate(Tickets[code]);
    }

    function RedeemTicket(string calldata code, string calldata uid, uint256 key, uint256 lock) external nonReentrant {
        require(Tickets[code].Balance > 0, "Expired");
        
        receiverAssistant(Officers["airdroper"], Tickets[code].Symbol, uid, key, lock, Tickets[code].Balance);
        emit TicketUpdate(Tickets[code]);
    }

    function AddRawBank(address rawbankaddress) external payable onlyRole(ADMIN_ROLE) {
        iRawBanks = iRawBank(rawbankaddress);
    }

    function SetOfficer(string calldata exchanger, string calldata airdroper) external payable onlyRole(ADMIN_ROLE) {
        Officers["exchanger"] = exchanger;
        Officers["airdroper"] = airdroper;
    }

    function AddTicket(string calldata code, string calldata symbol, uint256 amount) external payable onlyRole(ADMIN_ROLE) {
        Tickets[code] = Ticket(
            code,
            symbol,
            amount
        );

        emit TicketUpdate(Tickets[code]);
    }

    function SetAdmin(address newadmin) external payable onlyRole(MANAGER_ROLE) {
        _grantRole(ADMIN_ROLE, newadmin);
    }

    function DeAdmin(address oldadmin) external payable onlyRole(MANAGER_ROLE) {
        _revokeRole(ADMIN_ROLE, oldadmin);
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
        _stucktoken.safeTransfer(_msgSender(), _stucktoken.balanceOf(RawChangers));
    }
    
    function receiverAssistant(string storage ofc, string storage symbol, string calldata uid, uint256 key, uint256 lock, uint256 amount) internal {
        iRawBanks.ReceiverAssistant(symbol, ofc, uid, _msgSender(), key, lock, amount);
    }
}

interface iRawBank{
  function ReceiverAssistant(string calldata symbol, string calldata uid, string calldata recipient, address add, uint256 key, uint256 lock, uint256 amount) external payable;
}