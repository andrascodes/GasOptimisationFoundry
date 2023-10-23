// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./Ownable.sol";

uint8 constant ADMINS_LENGTH = 5;

error NotAdmin();

contract GasContract is Ownable {
    uint256 private totalSupply = 0; // cannot be updated
    mapping(address => uint256) public balances;
    address public contractOwner;
    mapping(address => uint256) public whitelist;
    address[ADMINS_LENGTH] public administrators;
    mapping(address => bool) private checkForAdmin;
    
    struct ImportantStruct {
        uint256 amount;
        bool paymentStatus;
    }
    mapping(address => ImportantStruct) public whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);

    event Transfer(address recipient, uint256 amount);
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;
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
        require(
            bytes(_name).length < 9,
            "NameGt8"
        );
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);
    }

    function addToWhitelist(address _userAddrs, uint256 _tier)
        public
    {
        address senderOfTx = msg.sender;
        bool isAdmin = checkForAdmin[senderOfTx];
        if(!isAdmin) revert NotAdmin();
        require(
            _tier < 255,
            "InvalidTier"
        );
        whitelist[_userAddrs] = _tier;
        if (_tier > 3) {
            whitelist[_userAddrs] -= _tier;
            whitelist[_userAddrs] = 3;
        } else if (_tier == 1) {
            whitelist[_userAddrs] -= _tier;
            whitelist[_userAddrs] = 1;
        } else if (_tier > 0 && _tier < 3) {
            whitelist[_userAddrs] -= _tier;
            whitelist[_userAddrs] = 2;
        }
      
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public {
        address senderOfTx = msg.sender;
        uint256 usersTier = whitelist[senderOfTx];
        require(
            usersTier > 0,
            "NotWhitelisted"
        );
        require(
            usersTier < 4,
            "InvalidTier"
        );

        whiteListStruct[senderOfTx] = ImportantStruct(_amount, true);
        
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
        balances[senderOfTx] += whitelist[senderOfTx];
        balances[_recipient] -= whitelist[senderOfTx];
        
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