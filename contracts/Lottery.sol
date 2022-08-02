// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

pragma solidity ^0.8.7;

contract Lottery {
    using Counters for Counters.Counter;
    Counters.Counter public totalParticipation;

    address public owner;
    uint public immutable entryPrice;
    uint public immutable maxParticipancePerUser;
    uint public immutable minimumParticipationAmount;

    // If you want to spend less gas
    // you should consider using shorter
    // variable names. Since this is an example,
    // I try to make it more readable

    address[] private entries;

    mapping(address=>uint) addressToTotalParticipation;


    modifier maxParticipationAmountNotExceeded() {
        require(addressToTotalParticipation[msg.sender] < maxParticipancePerUser, "You've exceeded max participation amount.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier enoughtParticipation() {
        require(totalParticipation.current() >= minimumParticipationAmount, "Not enough participations.");
        _;
    }

    constructor(uint _entryPrice, uint _maxParticipancePerUser, uint _minimumParticipationAmount) {
        owner = msg.sender;
        entryPrice = _entryPrice * 10 **18;
        maxParticipancePerUser = _maxParticipancePerUser;
        minimumParticipationAmount = _minimumParticipationAmount;
    }

    function participate() external payable maxParticipationAmountNotExceeded() {
        require(msg.value >= entryPrice, "Value can not be lower than entry price.");
        entries.push(msg.sender);
        totalParticipation.increment();
        addressToTotalParticipation[msg.sender] += 1;
    }

    function endLottery() external payable onlyOwner() enoughtParticipation() {
        address[] memory _entries = entries;
        bool flag = true;
        uint i;
        while(flag) {
            i = getRandomNumber();
            if (_entries[i] != address(0)) {
                payable(_entries[i]).transfer(totalParticipation.current() * entryPrice);
                flag = false;
            }
        }

    }

    // User have to pay if the want to remove their participations
    // it's 10% of total participation amount. So they'll get 90% of 
    // their total entries

    function removeParticipations() external payable {
        uint _minusRemoveFee = ((addressToTotalParticipation[msg.sender] * entryPrice) / 100) * 90;
        delete addressToTotalParticipation[msg.sender];

        address[] memory _entries = entries;
        uint _totalParticipation = totalParticipation.current();
        // incrementing i in here is not good for 
        // gas cost
        for (uint i = 0 ; i < _totalParticipation; i++) {
            if (_entries[i] == msg.sender) {
                delete entries[i];
                totalParticipation.decrement();
            }
        }
        payable(msg.sender).transfer(_minusRemoveFee);
    }


    function getUserParticipationAmount() public view returns(uint) {
        return addressToTotalParticipation[msg.sender];
    }

    function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getRandomNumber() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, totalParticipation.current())));
    }

}