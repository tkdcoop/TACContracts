//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

//TAC Lockup contract receives 7% of all TAC when the contract is created.
//Management and advisors can claim 20% of their allocation each year for 5 years

//Control who can access various functions. 
contract AccessControl {
    address payable public creatorAddress;

    modifier onlyCREATOR() {
        require(msg.sender == creatorAddress);
        _;
    }
   // Constructor
    constructor() {
        creatorAddress = msg.sender;
    }
} 

//Interface to main TAC contract to effect transfers. 
abstract contract ITACData {
    function transfer(address recipient, uint256 amount) public virtual returns (bool) ;
}

contract TACAdvisorLockup is AccessControl  {

     /////////////////////////////////////////////////DATA STRUCTURES AND GLOBAL VARIABLES ///////////////////////////////////////////////////////////////////////

    //Lockup duration in seconds - 1 year on mainnet, less for testing.
    uint64 public lockupDuration = 604800;

    struct Beneficiary {
        address beneficaryAddress;
        uint256 periodAllocation; //how much they are allowed to have each period
        uint256 balance; //The total amount they have remaining
    }

    Beneficiary[] Beneficiaries;
    
    //Change to current value once deployed. 
    address TACContract = address(0);
    
    //Ensure allocations can only be give once. 
    bool contractInitialized = false;
    
    //Lockup starts when contract initialized
    uint64 contractInitializedTime;

    //Initial function to set creation time and beneficiary designations.
    function initContract() public {

        require(contractInitialized == false,  "This contract has already been initialized");
        contractInitializedTime = uint64(block.timestamp);
        contractInitialized = true;

        // 000000000000000000 - 18 zeroes
        //initialize beneficiaries
        Beneficiary memory beneficiary;
        beneficiary.beneficaryAddress = 0xf934bfd04f1a4DCa2C7dDAcC5D59ECb71059FdBA;
        beneficiary.periodAllocation = 2400000000000000000000000;
        beneficiary.balance = beneficiary.periodAllocation * 5;
        Beneficiaries.push(beneficiary);

        beneficiary.beneficaryAddress = 0xb860E2Ba02147a5B849c39537A6C50d942A829Fe;
        beneficiary.periodAllocation = 2400000000000000000000000;
        beneficiary.balance = beneficiary.periodAllocation * 5;
        Beneficiaries.push(beneficiary);
      
        beneficiary.beneficaryAddress = 0xf3c4DE3651AbC15584d28b77C4d1B304A9818Fd0;
        beneficiary.periodAllocation = 2400000000000000000000000;
        beneficiary.balance = beneficiary.periodAllocation * 5;
        Beneficiaries.push(beneficiary);

        beneficiary.beneficaryAddress = 0xF2d4Bc74da733c2B0842D3c9F0B8C32c9aA7d6B3;
        beneficiary.periodAllocation = 1800000000000000000000000;
        beneficiary.balance = beneficiary.periodAllocation * 5;
        Beneficiaries.push(beneficiary);

        beneficiary.beneficaryAddress = 0x7207cE1473F7117E365216E1F92C3709dFa33b3C;
        beneficiary.periodAllocation = 1200000000000000000000000;
        beneficiary.balance = beneficiary.periodAllocation * 5;
        Beneficiaries.push(beneficiary);

        beneficiary.beneficaryAddress = 0x0C00D314465231bcCA8c980091E75faBd98AF84A;
        beneficiary.periodAllocation = 900000000000000000000000;
        beneficiary.balance = beneficiary.periodAllocation * 5;
        Beneficiaries.push(beneficiary);

        beneficiary.beneficaryAddress = 0x682d96C807400b01fa3fe609Ae552902BD005640;
        beneficiary.periodAllocation = 500000000000000000000000;
        beneficiary.balance = beneficiary.periodAllocation * 5;
        Beneficiaries.push(beneficiary);

        beneficiary.beneficaryAddress = 0x147f0692c258Bc813Ccd13E35DA2ffEB39e09221;
        beneficiary.periodAllocation = 500000000000000000000000;
        beneficiary.balance = beneficiary.periodAllocation * 5;
        Beneficiaries.push(beneficiary);

        beneficiary.beneficaryAddress = 0xC30a96bEd7608F0793f9D1cAA50004AE5D6Ce882;
        beneficiary.periodAllocation = 600000000000000000000000;
        beneficiary.balance = beneficiary.periodAllocation * 5;
        Beneficiaries.push(beneficiary);

        beneficiary.beneficaryAddress = 0x97daC781bf0d4f685eEc2eB41296CD78F183D0e2;
        beneficiary.periodAllocation = 200000000000000000000000;
        beneficiary.balance = beneficiary.periodAllocation * 5;
        Beneficiaries.push(beneficiary);
        
        beneficiary.beneficaryAddress = 0xF708183A8A379C187fd684f6c607ae394679Ea81;
        beneficiary.periodAllocation = 200000000000000000000000;
        beneficiary.balance = beneficiary.periodAllocation * 5;
        Beneficiaries.push(beneficiary);

        beneficiary.beneficaryAddress = 0xd246f7484F696ccf9BAc2ea60330Dd9A3C332eff;
        beneficiary.periodAllocation = 200000000000000000000000;
        beneficiary.balance = beneficiary.periodAllocation * 5;
        Beneficiaries.push(beneficiary);

        beneficiary.beneficaryAddress = 0xD86B7Ce16699D91dbf0807674E2dbB615447c4F1;
        beneficiary.periodAllocation = 200000000000000000000000;
        beneficiary.balance = beneficiary.periodAllocation * 5;
        Beneficiaries.push(beneficiary);

        beneficiary.beneficaryAddress = 0x454b0cbc0aF7B3cE3722365F62083c5F9a3C2e6E;
        beneficiary.periodAllocation = 200000000000000000000000;
        beneficiary.balance = beneficiary.periodAllocation * 5;
        Beneficiaries.push(beneficiary);

        beneficiary.beneficaryAddress = 0xFB84c39BbAe367FED2b84930755493FaE00Fd572;
        beneficiary.periodAllocation = 100000000000000000000000;
        beneficiary.balance = beneficiary.periodAllocation * 5;
        Beneficiaries.push(beneficiary);

        beneficiary.beneficaryAddress = 0xbd661e79c7945232CB2A07109b34a7a513313999;
        beneficiary.periodAllocation = 100000000000000000000000;
        beneficiary.balance = beneficiary.periodAllocation * 5;
        Beneficiaries.push(beneficiary);

        beneficiary.beneficaryAddress = 0xB22FAB8183e7AA66D2653b963acdD8B7BB8c36B6;
        beneficiary.periodAllocation = 100000000000000000000000;
        beneficiary.balance = beneficiary.periodAllocation * 5;
        Beneficiaries.push(beneficiary);

    }

    function setTACAddress(address _TACContract) public onlyCREATOR {
        TACContract = _TACContract;
    }

    //DEV FUNCTION 
    function setBeneficiaryAddress(uint8 number, address newAddress) public onlyCREATOR {
        Beneficiaries[number].beneficaryAddress = newAddress;
    }

    //Returns values in the contract. 
    function getValues() public view returns (uint64 _lockupDuration,
    address _TACContract, bool _initialized, uint64 _contractInitializedTime) {
        _lockupDuration = lockupDuration;
        _TACContract = TACContract;
        _initialized = contractInitialized;
        _contractInitializedTime = contractInitializedTime;
    }

    //Returns the number of lockup periods (ie, years) that have passed since the contract was initialized.
    function getFullLockupPeriods() public view returns (uint8 periods) {
        periods = 0;
        if (block.timestamp >= contractInitializedTime + lockupDuration) {
            periods += 1;
        }
        if (block.timestamp >= contractInitializedTime + lockupDuration * 2) {
            periods += 1;
        }
        if (block.timestamp >= contractInitializedTime + lockupDuration * 3) {
            periods += 1;
        }
        if (block.timestamp >= contractInitializedTime + lockupDuration * 4) {
            periods += 1;
        }
        if (block.timestamp >= contractInitializedTime + lockupDuration * 5) {
            periods += 1;
        }
        return periods;

    }

    //Any of the beneficiaries can call this function to claim the TAC they are entitled to.
    function claimTAC() public {
        ITACData TAC = ITACData(TACContract);

        //Find the beneficiary.
        for (uint i = 0; i<Beneficiaries.length; i++) {
          if (Beneficiaries[i].beneficaryAddress == msg.sender) {
              
            // Transfer all balance at the end
            if (getFullLockupPeriods() >= 5) {
                Beneficiaries[i].balance = 0;
                TAC.transfer(msg.sender, Beneficiaries[i].balance);
                return;
            }
            
            uint256 entitled = getFullLockupPeriods() * Beneficiaries[i].periodAllocation;
            uint256 totalAllocation = Beneficiaries[i].periodAllocation * 5;
            
            if ((totalAllocation) - entitled < Beneficiaries[i].balance) {
                
                // transfer what they are entitled to minus what they have already claimed
                uint256 toTransfer = entitled - (totalAllocation - Beneficiaries[i].balance);
                
                Beneficiaries[i].balance = totalAllocation - entitled;
                TAC.transfer(msg.sender, toTransfer);
            }
          }
        }
    }
}
