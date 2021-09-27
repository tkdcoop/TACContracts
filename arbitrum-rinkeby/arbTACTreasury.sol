//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Control who can access various functions.
contract AccessControl {
    address payable public creatorAddress;

    modifier onlyCREATOR() {
        require(
            msg.sender == creatorAddress,
            "You are not the creator of this contract"
        );
        _;
    }

    // Constructor
    constructor() {
        creatorAddress = payable(0x813dd04A76A716634968822f4D30Dfe359641194);
    }
}

// Allows this contract to add to an address's locked TAC balance.
abstract contract ITACLockup {
    function adjustBalance(address user, uint256 amount) public virtual;
}

abstract contract ITAC {
    function balanceOf(address user) public virtual returns (uint256);

    function transfer(address recipient, uint256 amount) public virtual;
}

// Main Contract
contract TACTreasury is AccessControl {
    /////////////////////////////////////////////////DATA STRUCTURES AND GLOBAL VARIABLES ///////////////////////////////////////////////////////////////////////

    // 000000000000000000 - 18 zeroes

    //Base TAC distribution values for each match participant.

    uint16 public multiplier = 10; //How much the below values are multiplied by to get the final distribution.

    uint256 athleteBase = 2000000000000000000;
    uint256 refBase = 1000000000000000000;
    uint256 poolBase = 1000000000000000000;

    //Address that awards bonus TAC for winning 'match of the week'
    address public votingPoolContract =
        0x0C00D314465231bcCA8c980091E75faBd98AF84A;
    //Contract that time-delays release of TAC.
    address public lockupContract = 0x87065C29E52F1f3a2AFC92bF7911e0F773E3B619;
    //Contract that keeps coop data like users, matches, etc.
    address public coopDataContract =
        0x3B41f9F7aDab4B06faf6164E4dD84B3935344E6f;
    // Contract that keeeps data about events.
    address public eventsContract = 0xb030a908B666b37Ba37e22681D931F93349A1055;

    address public tACContract = address(0);

    /////////////////////////////////////////////////////////TAC CONTRACT CONTROL FUNCTIONS //////////////////////////////////////////////////

    function changeParameters(
        uint16 _multiplier,
        address _coopDataContract,
        address _votingPoolContract,
        address _eventsContract,
        address _lockupContract,
        address _tACContract
    ) external onlyCREATOR {
        multiplier = _multiplier;
        coopDataContract = _coopDataContract;
        votingPoolContract = _votingPoolContract;
        eventsContract = _eventsContract;
        lockupContract = _lockupContract;
        tACContract = _tACContract;
    }

    //Function called by coopDataContract to award TAC and lock it up.
    function awardTAC(
        address winner,
        address loser,
        address referee
    ) public {
        require(
            msg.sender == coopDataContract || msg.sender == eventsContract,
            "Only the CoopData and Events Contracts may call this function"
        );

        ITACLockup TACLockup = ITACLockup(lockupContract);
        ITAC TAC = ITAC(tACContract);

        uint256 tokensToIssue = (athleteBase +
            athleteBase +
            poolBase +
            refBase) * multiplier;
        if (tokensToIssue <= TAC.balanceOf(address(this))) {
            //credit the athletes
            TAC.transfer(lockupContract, 2 * athleteBase * multiplier);
            TACLockup.adjustBalance(winner, athleteBase * multiplier);
            TACLockup.adjustBalance(loser, athleteBase * multiplier);

            //credit the ref
            TAC.transfer(lockupContract, refBase * multiplier);
            TACLockup.adjustBalance(referee, refBase * multiplier);

            //credit the voting pool
            TAC.transfer(votingPoolContract, poolBase * multiplier);
        }
    }

    //Function called by coopDataContract to award TAC and lock it up.
    function awardTrainingTAC(address athlete, address referee) public {
        require(
            msg.sender == coopDataContract,
            "Only the CoopData Contract may call this function"
        );

        ITACLockup TACLockup = ITACLockup(lockupContract);
        ITAC TAC = ITAC(tACContract);

        uint256 tokensToIssue = (athleteBase + poolBase + refBase) * multiplier;
        if (tokensToIssue <= TAC.balanceOf(address(this))) {
            //credit the athlete
            TAC.transfer(lockupContract, 2 * athleteBase * multiplier);
            TACLockup.adjustBalance(athlete, athleteBase * multiplier);

            //credit the ref
            TAC.transfer(lockupContract, refBase * multiplier);
            TACLockup.adjustBalance(referee, refBase * multiplier);

            //credit the voting pool
            TAC.transfer(votingPoolContract, poolBase * multiplier);
        }
    }
}
