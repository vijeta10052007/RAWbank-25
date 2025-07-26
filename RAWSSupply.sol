// SPDX-License-Identifier: NONE

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RAWSSupply is ERC20, AccessControl, ERC20Permit, ReentrancyGuard {
    bytes32 internal constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 internal constant MaxSupply = 1600000000;

    struct Allocation {
        string Utility;
        address Entitled;
        uint256 Right;
        uint256 Balance;
        uint256 Unlock;
        uint256 Monthly;
        uint256 Cliff;
    }

    string[] public Utilities;
    uint256 internal Allocated;
    uint256 internal Taked;

    mapping(string => Allocation) public Allocations;
    
    constructor() payable
        ERC20("Reign Alter World Sovereign", "RAWS")
        ERC20Permit("Reign Alter World Sovereign")
    {
        _grantRole(MANAGER_ROLE, msg.sender);
    }

    event AllocationUpdate(Allocation result);

    function Allocate(string calldata utility, address entitled, uint256 right, uint256 cliff, uint256 unlock, uint256 monthly) external onlyRole(MANAGER_ROLE) {
        require(Allocations[utility].Entitled == address(0x0), "Already Exist");
        require(Allocated + right <= MaxSupply, "Max Supply Reach");
        
        Allocations[utility] = Allocation (
            utility, entitled, right, right, unlock * 10, monthly * 10, block.timestamp + cliff * 60 * 60 * 24 * 30
        );

        Allocated += right;
        Utilities.push(utility);
        _grantRole(MINTER_ROLE, entitled);

        emit AllocationUpdate(Allocations[utility]);
    }

    function Reallocate(string calldata utility, address entitled, uint256 right, uint256 cliff, uint256 unlock, uint256 monthly) external onlyRole(MANAGER_ROLE) {
        require(Allocations[utility].Entitled != address(0x0), "Not Exist");
        require(Allocated - Allocations[utility].Right + right <= MaxSupply, "Max Supply Reach");

        _revokeRole(MINTER_ROLE, Allocations[utility].Entitled);
        _grantRole(MINTER_ROLE, entitled);

        Allocated = Allocated - Allocations[utility].Right + right;

        Allocations[utility].Monthly = monthly * 10;
        Allocations[utility].Unlock = unlock * 10;
        Allocations[utility].Cliff = block.timestamp + cliff * 60 * 60 * 24 * 30;
        Allocations[utility].Balance = right - (Allocations[utility].Right - Allocations[utility].Balance);
        Allocations[utility].Right = right;
        Allocations[utility].Entitled = entitled;

        emit AllocationUpdate(Allocations[utility]);
    }

    function TakeRight(string calldata utility, uint256 amount) external payable nonReentrant onlyRole(MINTER_ROLE) {
        require(_msgSender() == Allocations[utility].Entitled, "Not Entitled");
        require(amount <= UtilityAllotment(utility) - Allocations[utility].Right - Allocations[utility].Balance, "Not Enough Utility Allocation");
        require(amount <= Allocations[utility].Balance, "Not Enough Utility Balance");
        require(totalSupply() / 10 ** decimals() + amount <= MaxSupply, "Max Supply Reach");

        Allocations[utility].Balance -= amount;
        Taked += amount;
        _mint(_msgSender(), amount * 10 ** decimals());

        emit AllocationUpdate(Allocations[utility]);
    }

    function UtilityAllotment(string calldata utility) public view returns (uint256) {
        uint256 _monthly = 0;

        if(block.timestamp > Allocations[utility].Cliff)
        {
            uint256 _counter = (block.timestamp - Allocations[utility].Cliff) / (60 * 60 * 24 * 30);
            _monthly = _counter * Allocations[utility].Monthly;
        }

        uint256 _percent = Allocations[utility].Unlock + _monthly;
        return Allocations[utility].Right * _percent / 1000;
    }

    function StuckTokens(address token) external onlyRole(MANAGER_ROLE) {
        if (token == address(0x0)) {
            payable(_msgSender()).transfer(address(this).balance);
            return;
        }
        require(Taked == totalSupply() / 10 ** decimals(), "Temporary Locked");
        
        ERC20 _stucktoken = ERC20(token);
        _stucktoken.transfer(_msgSender(), _stucktoken.balanceOf(address(this)));
    }
}