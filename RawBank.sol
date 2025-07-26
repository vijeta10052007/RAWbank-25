// SPDX-License-Identifier: NONE

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RawBank is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address RawBanks;

    bytes32 internal constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 internal constant AI_ROLE = keccak256("AI_ROLE");

    struct Token{
        string Symbol;
        string Name;
        address TokenAddress;
        uint256 UserDeposit;
        uint256 Order;
    }

    struct Account {
        address Wallet;
        uint256 Keys;
        uint256 Lock;
        uint256[] Balance;
    }

    struct Wallet {
        string Account;
        uint256 Keys;
    }

    struct Assistant {
        address Wallet;
    }

    uint256[] internal ChainList;
    
    mapping(string => Token) internal Tokens;

    mapping(string => Account) internal Accounts;

    mapping(address => Wallet) internal Wallets;

    mapping(string => Assistant) internal Assistants;

    event AccountUpdate(address wallet, string id, uint256[] balances);
    event BalanceUpdate(string status, string holder, uint256 amount, uint256 balance);

    constructor() payable {
        _grantRole(MANAGER_ROLE, msg.sender);
        RawBanks = address(this);
    }

    function GetToken(string calldata symbol) internal view returns(Token memory){
        return Tokens[symbol];
    }

    function CheckAuth(string calldata uid, address add, uint256 key) internal view returns (bool){
        return Accounts[uid].Keys == key && Wallets[add].Keys == key;
    }

    function Locking(string calldata uid, address add, uint256 lock) internal{
        uint256 _keys = (ChainList[lock] + Accounts[uid].Lock) % 999999;
        Accounts[uid].Keys = _keys;
        Wallets[add].Keys = _keys;
    }

    function CheckBalance(string calldata symbol, string calldata uid) external view returns (uint256) {
        return Accounts[uid].Balance[Tokens[symbol].Order];
    }

    function CreateAccount(string calldata uid, uint256 key, uint256 lock) external nonReentrant {
        require(Accounts[uid].Keys == 0, "Account Already Exist");
        require(Wallets[_msgSender()].Keys == 0, "Wallet Already Use");

        uint256 _keys = (ChainList[lock] + key) % 999999;

        Accounts[uid] = Account (
            _msgSender(),
            _keys,
            key,
            new uint256[](8)
        );

        Wallets[_msgSender()] = Wallet (
            uid,
            _keys
        );

        emit AccountUpdate(Accounts[uid].Wallet, uid, Accounts[uid].Balance);
    }

    function DepositBalance(string calldata symbol, string calldata uid, uint256 key, uint256 lock, uint256 amount) external nonReentrant {
        require(CheckAuth(uid, _msgSender(), key), "Not Authorized");
        
        Token memory _token = GetToken(symbol);
        uint256 _tokendecimal = ERC20(_token.TokenAddress).decimals();
        require(IERC20(_token.TokenAddress).balanceOf(_msgSender()) >= amount * 10 ** _tokendecimal, "insuficient Balance");

        IERC20(_token.TokenAddress).safeTransferFrom(_msgSender(), RawBanks, amount * 10 ** _tokendecimal);

        Tokens[symbol].UserDeposit += amount;
        uint256 _balance = Accounts[uid].Balance[Tokens[symbol].Order] + amount;
        Accounts[uid].Balance[Tokens[symbol].Order] = _balance;

        Locking(uid, _msgSender(), lock);
        emit BalanceUpdate("Deposit", uid, amount, _balance);
    }

    function RedeemBalance(string calldata symbol, string calldata uid, uint256 key, uint256 lock, uint256 amount) external nonReentrant {
        require(CheckAuth(uid, _msgSender(), key), "Not Authorized");
        
        Token memory _token = GetToken(symbol);

        require(Accounts[uid].Balance[Tokens[symbol].Order] >= amount, "Insufficient Balance");
        uint256 _tokendecimal = ERC20(_token.TokenAddress).decimals();
        require(IERC20(_token.TokenAddress).balanceOf(RawBanks) > amount * 10 ** _tokendecimal, "Please Contact RAWBank Admin");

        Tokens[symbol].UserDeposit -= amount;
        uint256 _balance = Accounts[uid].Balance[Tokens[symbol].Order] - amount;
        Accounts[uid].Balance[Tokens[symbol].Order] = _balance;

        IERC20(_token.TokenAddress).safeTransfer(_msgSender(), amount * 10 ** _tokendecimal);

        Locking(uid, _msgSender(), lock);
        emit BalanceUpdate("Redeem", uid, amount, _balance);
    }

    function TransferBalance(string calldata symbol, string calldata uid, uint256 key, uint256 lock, string calldata recipient, uint256 amount) external nonReentrant {
        require(CheckAuth(uid, _msgSender(), key), "Not Authorized");

        require(Accounts[uid].Balance[Tokens[symbol].Order] >= amount, "Insufficient Balance");
        uint256 _sBalance = Accounts[uid].Balance[Tokens[symbol].Order] - amount;
        Accounts[uid].Balance[Tokens[symbol].Order] = _sBalance;

        uint256 _rBalance = Accounts[recipient].Balance[Tokens[symbol].Order] + amount;
        Accounts[recipient].Balance[Tokens[symbol].Order] = _rBalance;

        Locking(uid, _msgSender(), lock);
        emit BalanceUpdate("Transfer", recipient, amount, _sBalance);
    }

    function EnableAssistant(string calldata uid, uint256 key, uint256 lock) external nonReentrant {
        require(CheckAuth(uid, _msgSender(), key), "Not Authorized");

        Locking(uid, _msgSender(), lock);
        Assistants[uid] = Assistant (
            _msgSender()
        );
    }

    function DisableAssistant(string calldata uid, uint256 key, uint256 lock) external nonReentrant {
        require(CheckAuth(uid, _msgSender(), key), "Not Authorized");

        Locking(uid, _msgSender(), lock);
        Assistants[uid] = Assistant (
            address(0x0)
        );
    }

    function ReceiverAssistant(string calldata symbol, string calldata uid, string calldata recipient, address add, uint256 key, uint256 lock, uint256 amount) external onlyRole(AI_ROLE) nonReentrant {
        require(CheckAuth(recipient, add, key), "Not Authorized");

        require(Assistants[uid].Wallet != address(0x0), "Not Assisted");
        require(Accounts[uid].Balance[Tokens[symbol].Order] >= amount, "Please Contact RAWBank Admin");

        uint256 _sBalance = Accounts[uid].Balance[Tokens[symbol].Order] - amount;
        Accounts[uid].Balance[Tokens[symbol].Order] = _sBalance;

        uint256 _rBalance = Accounts[recipient].Balance[Tokens[symbol].Order] + amount;
        Accounts[recipient].Balance[Tokens[symbol].Order] = _rBalance;

        Locking(recipient, add, lock);
        emit BalanceUpdate("Assistant", recipient, amount, _rBalance);
    }

    function SecureAccount(string calldata uid, uint256 key, uint256 lock) external nonReentrant {
        require(Accounts[uid].Keys == Wallets[_msgSender()].Keys, "Not Your Account");

        uint256 _keys = (ChainList[lock] + key) % 999999;

        Accounts[uid].Keys = _keys;
        Wallets[_msgSender()].Keys = _keys;

        emit AccountUpdate(Accounts[uid].Wallet, uid, Accounts[uid].Balance);
    }

    function ChangeWallet(string calldata uid, uint256 key, uint256 lock) external nonReentrant {
        require(Accounts[uid].Keys == key, "Not Your Account");

        require(Wallets[_msgSender()].Keys == 0, "Wallet Already Use");

        address _oldwallet = Accounts[uid].Wallet;
        
        Wallets[_msgSender()] = Wallet (
            uid,
            key
        );

        Wallets[_oldwallet].Keys = 0;
        Wallets[_oldwallet].Account = "";

        Accounts[uid].Wallet = _msgSender();

        Locking(uid, _msgSender(), lock);
        emit AccountUpdate(Accounts[uid].Wallet, uid, Accounts[uid].Balance);
    }

    function SwitchAccount(string calldata uid, uint256 key, uint256 lock) external nonReentrant {
        require(Wallets[_msgSender()].Keys == key, "Not Your Account");

        require(Accounts[uid].Keys == 0, "Account Already Exist");

        string storage _olduid = Wallets[_msgSender()].Account;

        Accounts[uid] = Account (
            _msgSender(),
            key,
            Accounts[_olduid].Lock,
            Accounts[_olduid].Balance
        );

        Accounts[_olduid].Wallet = address(0x0);
        Accounts[_olduid].Keys = 0;
        Accounts[_olduid].Lock = 0;
        Accounts[_olduid].Balance = new uint256[](8);

        Wallets[_msgSender()].Account = uid;

        Locking(uid, _msgSender(), lock);
        emit AccountUpdate(Accounts[uid].Wallet, uid, Accounts[uid].Balance);
    }

    function CheckAccount(string calldata uid) external onlyRole(ADMIN_ROLE) view returns (Account memory) {
        return Accounts[uid];
    }

    function CheckChainList(uint256 idx) external onlyRole(ADMIN_ROLE) view returns (uint256) {
        return ChainList[idx];
    }

    function AddLock() external payable onlyRole(ADMIN_ROLE) {
        bytes32 _lock = keccak256(abi.encodePacked(msg.sender, block.timestamp, block.prevrandao));
        uint256 _key = uint256(_lock) % 999999;
        
        ChainList.push(_key);
    }

    function AddToken(string calldata name, string calldata symbol, address tokenaddress, uint256 order) external payable onlyRole(ADMIN_ROLE) {
        Tokens[symbol] = Token(
            symbol,
            name,
            tokenaddress,
            0,
            order
        );
    }

    function SetAI(address newai) external payable onlyRole(MANAGER_ROLE) {
        _grantRole(AI_ROLE, newai);
    }

    function DeAI(address oldai) external payable onlyRole(MANAGER_ROLE) {
        _revokeRole(AI_ROLE, oldai);
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

    function StuckTokens(string calldata symbol, address token) external payable onlyRole(MANAGER_ROLE) {
        if (token == address(0x0)) {
            payable(_msgSender()).transfer(address(this).balance);
            return;
        }
        Token memory _token = GetToken(symbol);

        require(_token.TokenAddress == token, "Temporary Locked");
        IERC20 _stucktoken = IERC20(token);
        uint256 _stuckbalance = _stucktoken.balanceOf(RawBanks);

        require(_token.UserDeposit < _stuckbalance, "Temporary Locked");
        _stucktoken.safeTransfer(_msgSender(), _stuckbalance - _token.UserDeposit);
    }
}