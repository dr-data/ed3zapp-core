// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ISuperfluid } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import { IConstantFlowAgreementV1 } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

import { ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";

import {
    CFAv1Library
} from "@superfluid-finance/ethereum-contracts/contracts/apps/CFAv1Library.sol";

interface USDC {

    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

contract Purchase {
    USDC public USDc;
    address owner;
    mapping(address => uint) public stakingBalance;
    using CFAv1Library for CFAv1Library.InitData;
    //initialize cfaV1 variable
    CFAv1Library.InitData public cfaV1;

    constructor( ISuperfluid host ) {
        USDc = USDC(0xbe49ac1EadAc65dccf204D4Df81d650B50122aB2);
        owner = msg.sender;

        //initialize InitData struct, and set equal to cfaV1
            //initialize InitData struct, and set equal to cfaV1
        cfaV1 = CFAv1Library.InitData( host,
        //here, we are deriving the address of the CFA using the host contract
        IConstantFlowAgreementV1(
            address(host.getAgreementClass(
                    keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1")
                ))
            )
        );
       
    }

            
    function buyCourse(uint $USDC, address contentCreator, int96 flowRate,  bool isNewStream, int96 updatedFlowRate) public {

        // amount should be > 0
        uint256 totalAmount = $USDC * 10 ** 18;
        uint256 platformAmount = totalAmount/2;
        uint256 contentCreatorAmount = totalAmount/2;

        // transfer USDC to this contract
        USDc.transferFrom(msg.sender, address(this), platformAmount);

        // update staking balance
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + platformAmount;

        //To do flow Wrap USDCx
        //Upgrading USDC to USDCx super token   

        //address public superTokenAddress = 0x42bb40bF79730451B11f6De1CbA222F17b87Afd7;
        
        // approving
        USDc.approve(0x42bb40bF79730451B11f6De1CbA222F17b87Afd7, contentCreatorAmount);

        // wrapping
        ISuperToken(0x42bb40bF79730451B11f6De1CbA222F17b87Afd7).upgrade(contentCreatorAmount);

        //contentCreator
        //ISuperToken(0x42bb40bF79730451B11f6De1CbA222F17b87Afd7).transfer(contentCreator, contentCreatorAmount);

        // CFA CRUD functionality
        //cfaV1.createFlow(receiver, token, flowRate);
        //Flowrate to be calculated from the frontend
        //int96 flowRate = 20000000000000;
        //Need to check existing flow before creating new one, should invoke updateFlow incase flow already exist
        //Check can be done by using graph

        if(isNewStream) {
            cfaV1.createFlow(contentCreator, ISuperToken(0x42bb40bF79730451B11f6De1CbA222F17b87Afd7), flowRate);
        }
        else {
            cfaV1.updateFlow(contentCreator, ISuperToken(0x42bb40bF79730451B11f6De1CbA222F17b87Afd7), updatedFlowRate);
        }
        

    }

    // Unstaking Tokens (Withdraw)
    function claimReward(uint bounty) public {
        uint balance = stakingBalance[msg.sender];

        uint bountywei = bounty * 10 ** 18;

        // balance should be > 0
        require (balance > 0, "staking balance cannot be 0");

        // Transfer USDC tokens to the users wallet
        USDc.transfer(msg.sender, bountywei);

        // decrease balance after sending reward
        stakingBalance[msg.sender] = balance - bountywei;
    }

}