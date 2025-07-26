// SPDX-License-Identifier: NONE

pragma solidity 0.8.19; 

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RAWGld is ERC20, AccessControl, ERC20Permit, ReentrancyGuard {
    bytes32 internal constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 internal constant MaxSupply = 20480000000;

    struct Allocation {
        string Utility;
        address Entitled;
        uint256 Right;
        uint256 Balance;
    }

    string[] public Utilities;
    uint256 internal Allocated;
    uint256 internal Taked;

    mapping(string => Allocation) public Allocations;
    
    constructor() payable
        ERC20("Reign Alter World Gold", "RAWGld")
        ERC20Permit("Reign Alter World Gold")
    {
        _grantRole(MANAGER_ROLE, msg.sender);
    }

    event AllocationUpdate(Allocation result);

    function Allocate(string calldata utility, address entitled) external onlyRole(MANAGER_ROLE) {
        require(Allocations[utility].Entitled == address(0x0), "Already Exist");
        require(Allocated + MaxSupply / 160 <= MaxSupply, "Max Supply Reach");
        
        Allocations[utility] = Allocation (
            utility, entitled, MaxSupply / 160, MaxSupply / 160
        );

        Allocated += MaxSupply / 160;
        Utilities.push(utility);
        _grantRole(MINTER_ROLE, entitled);

        emit AllocationUpdate(Allocations[utility]);
    }

    function Reallocate(string calldata utility, address entitled) external onlyRole(MANAGER_ROLE) {
        require(Allocations[utility].Entitled != address(0x0), "Not Exist");

        _revokeRole(MINTER_ROLE, Allocations[utility].Entitled);
        _grantRole(MINTER_ROLE, entitled);

        Allocations[utility].Entitled = entitled;

        emit AllocationUpdate(Allocations[utility]);
    }

    function TakeRight(string calldata utility, uint256 amount) external payable nonReentrant onlyRole(MINTER_ROLE) {
        require(_msgSender() == Allocations[utility].Entitled, "Not Entitled");
        require(amount <= Allocations[utility].Right - (Allocations[utility].Right - Allocations[utility].Balance), "Not Enough Utility Allocation");
        require(amount <= Allocations[utility].Balance, "Not Enough Utility Balance");
        require(totalSupply() / 10 ** decimals() + amount <= MaxSupply, "Max Supply Reach");

        Allocations[utility].Balance -= amount;
        Taked += amount;
        _mint(_msgSender(), amount * 10 ** decimals());

        emit AllocationUpdate(Allocations[utility]);
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