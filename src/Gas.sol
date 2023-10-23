// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./Ownable.sol";

uint8 constant ADMINS_LENGTH = 5;

error NotAdmin();
error InvalidTier();

contract GasContract is Ownable {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    address[ADMINS_LENGTH] public administrators;
    mapping(address => bool) private checkForAdmin;
    
    struct ImportantStruct {
        uint256 amount;
        bool paymentStatus;
    }
    mapping(address => ImportantStruct) public whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        address contractOwner = msg.sender;
        balances[contractOwner] = _totalSupply;
        checkForAdmin[contractOwner] = true;
        address[ADMINS_LENGTH] memory admins = [
            _admins[0],
            _admins[1],
            _admins[2],
            _admins[3],
            _admins[4]
        ];
        checkForAdmin[admins[0]] = true;
        checkForAdmin[admins[1]] = true;
        checkForAdmin[admins[2]] = true;
        checkForAdmin[admins[3]] = true;
        checkForAdmin[admins[4]] = true;
        administrators = admins;

    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        uint256 balance = balances[_user];
        return balance;
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public {
        address senderOfTx = msg.sender;
        require(
            balances[senderOfTx] >= _amount,
            "InsufficientBalance"
        );
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
    }

    function addToWhitelist(address _userAddrs, uint256 _tier)
        public
    {
        address senderOfTx = msg.sender;
        bool isAdmin = checkForAdmin[senderOfTx];
        if(!isAdmin) revert NotAdmin();

        if(_tier >= 255) revert InvalidTier();

        uint256 tier = _tier;
        if(_tier > 3) {
            tier = 3;
        } 
        whitelist[_userAddrs] = tier;
        
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public {
        address senderOfTx = msg.sender;
        uint256 usersTier = whitelist[senderOfTx];

        require(
            balances[senderOfTx] >= _amount,
            "InsufficientBalance"
        );
        require(
            _amount > 3,
            "AmountLte3"
        );
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        balances[senderOfTx] += usersTier;
        balances[_recipient] -= usersTier;
        
        whiteListStruct[senderOfTx] = ImportantStruct(_amount, true);
        emit WhiteListTransfer(_recipient);
    }


    function getPaymentStatus(address sender) public view returns (bool, uint256) {        
        return (whiteListStruct[sender].paymentStatus, whiteListStruct[sender].amount);
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }


    fallback() external payable {
         payable(msg.sender).transfer(msg.value);
    }
}