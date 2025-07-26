// SPDX-License-Identifier: NONE

pragma solidity 0.8.19; 

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract eRawChanger is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address eRawChangers;
    
    bytes32 internal constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct Token{
        string Symbol;
        address TokenAddress;
        uint256 Idx;
    }

    struct Taxs {
        uint256 Tax;
        uint256 Balance;
    }

    struct Wallet {
        uint256 Lock;
        uint256 Keys;
        uint256 RAWS;
    }

    uint256 CurrentTokenIdx;
    uint256[] internal ChainList;

    mapping(string => Token) internal Tokens;
    mapping(string => Taxs) internal Taxes;
    mapping(address => Wallet) internal Wallets;

    constructor() payable {
        _grantRole(MANAGER_ROLE, msg.sender);
        eRawChangers = address(this);
    }

    function GetTaxes(string calldata name) internal view returns(Taxs memory){
        return Taxes[name];
    }

    function GetToken(string calldata name) internal view returns(Token memory){
        return Tokens[name];
    }

    function Save(string calldata token, uint256 key, uint256 lock, uint256 amount) external nonReentrant {
        Token memory _token = GetToken(token);

        require(_token.Idx != 0, "Wrong Token");

        Taxs memory _taxes = GetTaxes(token);
        uint256 _tokendecimal = ERC20(_token.TokenAddress).decimals();
        uint256 _tokenamount = amount - amount * _taxes.Tax;

        require(IERC20(_token.TokenAddress).balanceOf(eRawChangers) >= _tokenamount * 10 ** _tokendecimal, "Temporary Close");
        
        if(Wallets[_msgSender()].Keys == 0)
        {
            Wallets[_msgSender()] = Wallet (
                key,
                key,
                0
            );
        }

        require(Wallets[_msgSender()].Keys == key, "Not Authorized");

        IERC20(_token.TokenAddress).safeTransfer(_msgSender(), _tokenamount * 10 ** _tokendecimal);
        
        uint256 _lock = (ChainList[lock] + Wallets[_msgSender()].Lock) % 999999;
        Wallets[_msgSender()].Keys = _lock;
    }

    function Exchange(string calldata nama, string calldata namb, uint256 amount) external nonReentrant {
        require(amount % 100 == 0, "Rate Not Match");

        Token memory _tokena = GetToken(nama);
        Token memory _tokenb = GetToken(namb);

        require(_tokena.Idx != 0, "Wrong Token");
        require(_tokenb.Idx != 0, "Wrong Token");
        require(_tokenb.Idx > _tokena.Idx, "Wrong Token");

        Taxs memory _taxes = GetTaxes(nama);
        uint256 _decimala = ERC20(_tokena.TokenAddress).decimals();
        uint256 _decimalb = ERC20(_tokenb.TokenAddress).decimals();
        uint256 _amounta = amount + amount * _taxes.Tax;
        uint256 _amountb = amount / 100;

        require(IERC20(_tokena.TokenAddress).balanceOf(_msgSender()) >= _amounta * 10 ** _decimala, "insuficient Balance");
        require(IERC20(_tokenb.TokenAddress).balanceOf(eRawChangers) >= _amountb * 10 ** _decimalb, "Temporary Close");

        IERC20(_tokena.TokenAddress).safeTransferFrom(_msgSender(), eRawChangers, _amounta * 10 ** _decimala);
        IERC20(_tokenb.TokenAddress).safeTransfer(_msgSender(), _amountb * 10 ** _decimalb);
    }

    function CrossChange(string calldata tkn, uint256 amount) external nonReentrant{
        Token memory _token = GetToken(tkn);

        require(_token.Idx != 0, "Wrong Token");
        require(_token.Idx == CurrentTokenIdx, "Wrong Token");

        Taxs memory _taxes = GetTaxes(tkn);
        uint256 _tokendecimal = ERC20(_token.TokenAddress).decimals();
        uint256 _tokenamnt = amount + amount * _taxes.Tax;

        require(IERC20(_token.TokenAddress).balanceOf(_msgSender()) >= _tokenamnt * 10 ** _tokendecimal, "insuficient Balance");

        IERC20(_token.TokenAddress).safeTransferFrom(_msgSender(), eRawChangers, _tokenamnt * 10 ** _tokendecimal);
        Wallets[_msgSender()].RAWS = amount / 100;
    }

    function GetRAWS(address user) external view returns(uint256){
        return Wallets[user].RAWS;
    }

    function UseRAWS(uint256 amount) external nonReentrant{
        uint256 _raws = Wallets[_msgSender()].RAWS;

        require(_raws >= amount, "insuficient Balance");

        Wallets[_msgSender()].RAWS = amount - _raws;
    }

    function AddToken(string calldata name, string calldata symbol, address tokenaddress, uint256 tax) external payable onlyRole(ADMIN_ROLE) {
        CurrentTokenIdx++;
        Tokens[name] = Token(
            symbol,
            tokenaddress,
            CurrentTokenIdx
        );

        Taxes[name] = Taxs(
            tax,
            0
        );
    }

    function CheckChainList(uint256 idx) external onlyRole(ADMIN_ROLE) view returns (uint256) {
        return ChainList[idx];
    }

    function AddLock() external payable onlyRole(ADMIN_ROLE) {
        bytes32 _lock = keccak256(abi.encodePacked(msg.sender, block.timestamp, block.prevrandao));
        uint256 _key = uint256(_lock) % 999999;
        
        ChainList.push(_key);
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
        _stucktoken.safeTransfer(_msgSender(), _stucktoken.balanceOf(eRawChangers));
    }
}