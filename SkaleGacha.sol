// SPDX-License-Identifier: NONE

pragma solidity 0.8.19;

import "@dirtroad/skale-rng/contracts/RNG.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SkaleGacha is AccessControl, ReentrancyGuard, RNG {
    using SafeERC20 for IERC20;
    address SkaleGachas;
    
    bytes32 internal constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 TimeLimit;

    struct Presence {
        address UserID;
        uint256 TimeSign;
        uint256 OutCome;
    }

    mapping(address => Presence) internal Presences;

    event GachaOutCome(uint256 result, uint256 times);

    constructor() payable {
        _grantRole(MANAGER_ROLE, msg.sender);
        SkaleGachas = address(this);
    }

    function SignGacha() external nonReentrant {
        require(Presences[_msgSender()].UserID == address(0x0), "Gacha Signed");

        Presences[_msgSender()] = Presence (
            _msgSender(),
            block.timestamp - TimeLimit,
            999999
        );
    }

    function Gacha() external nonReentrant{
        require(Presences[_msgSender()].UserID != address(0x0), "Gacha Signed Yet");
        require(block.timestamp - Presences[_msgSender()].TimeSign > TimeLimit, "Gacha Taked");
        
        uint256 _outcome = getRandomRange(999999);
        
        Presences[_msgSender()].TimeSign = block.timestamp;
        Presences[_msgSender()].OutCome = _outcome;

        emit GachaOutCome(Presences[_msgSender()].OutCome, Presences[_msgSender()].TimeSign);
    }

    function LastGacha(address player) external view returns (uint256) {
        return Presences[player].OutCome;
    }

    function CheckGacha(address player) external view returns (bool) {
        return Presences[player].UserID != address(0x0) && block.timestamp - Presences[player].TimeSign > TimeLimit;
    }

    function LastSign(address player) external view returns (uint256) {
        return Presences[player].TimeSign;
    }

    function SetTimeLimit(uint256 hourlimit) external payable onlyRole(ADMIN_ROLE) {
        TimeLimit = hourlimit * 60 * 60;
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
        _stucktoken.safeTransfer(_msgSender(), _stucktoken.balanceOf(SkaleGachas));
    }
}