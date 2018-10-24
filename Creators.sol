pragma solidity ^0.4.24;
/** @title Creators. */
contract Creators{
  /** @dev Checks if message sender is a creator.
      */

  address public creator1;
  address public creator2;
  address public creator3;
  address public creator4;
  address public creator5;

  struct ChangeCreatorProposal{
    uint8 creatorNumber;
    address newCreator;
    bool c1;
    bool c2;
    bool c3;
    bool c4;
    bool c5;
  }

  mapping (uint256 => ChangeCreatorProposal) changeCreatorProposals;

  /** @dev Constructor that sets the address for charity and creator.
      * @param _creator1 Creator1 address.
      * @param _creator1 Creator2 address.
      * @param _creator1 Creator3 address.
      * @param _creator1 Creator4 address.
      * @param _creator1 Creator5 address.
      */
  constructor(address _creator1, address _creator2, address _creator3, address _creator4, address _creator5) public {
    creator1 = _creator1;
    creator2 = _creator2;
    creator3 = _creator3;
    creator4 = _creator4;
    creator5 = _creator5;
  }

  /** @dev Create change creator proposal.
        * @param _proposalNumber Proposal number.
        * @param _creatorNumber Creator number.
        * @param _newCreator New creator address.
        */
  function createProposal(uint256 _proposalNumber, uint8 _creatorNumber, address _newCreator) public {
    require(tx.origin == creator1 || tx.origin == creator2 || tx.origin == creator3 || tx.origin == creator4 || tx.origin == creator5);
    changeCreatorProposals[_proposalNumber] = ChangeCreatorProposal(_creatorNumber, _newCreator, false, false, false, false, false);
  }

  /** @dev Creator approves a change creator proposal.
        * @param _proposalNumber Proposal number.
        */
  function approveProposal(uint256 _proposalNumber) public {
    require(changeCreatorProposals[_proposalNumber].creatorNumber != 0 && (tx.origin == creator1 || tx.origin == creator2 || tx.origin == creator3 || tx.origin == creator4 || tx.origin == creator5));
    if(tx.origin == creator1){
      changeCreatorProposals[_proposalNumber].c1 = true;
    }else if (tx.origin == creator2){
      changeCreatorProposals[_proposalNumber].c2 = true;
    }else if (tx.origin == creator3){
      changeCreatorProposals[_proposalNumber].c3 = true;
    }else if (tx.origin == creator4){
      changeCreatorProposals[_proposalNumber].c4 = true;
    }else if (tx.origin == creator5){
      changeCreatorProposals[_proposalNumber].c5 = true;
    }
  }

  /** @dev Change creator address.
        * @param _proposalNumber Proposal number.
        */
  function change(uint256 _proposalNumber) public {
    require(tx.origin == creator1 || tx.origin == creator2 || tx.origin == creator3 || tx.origin == creator4 || tx.origin == creator5);
    uint256 approvals = 0;
    if(changeCreatorProposals[_proposalNumber].c1 == true){
      approvals++;
    }
    if(changeCreatorProposals[_proposalNumber].c2 == true){
      approvals++;
    }
    if(changeCreatorProposals[_proposalNumber].c3 == true){
      approvals++;
    }
    if(changeCreatorProposals[_proposalNumber].c4 == true){
      approvals++;
    }
    if(changeCreatorProposals[_proposalNumber].c5 == true){
      approvals++;
    }
    require(approvals >= 3);
    if(changeCreatorProposals[_proposalNumber].creatorNumber == 1){
      creator1 = changeCreatorProposals[_proposalNumber].newCreator;
    }else if (changeCreatorProposals[_proposalNumber].creatorNumber == 2){
      creator2 = changeCreatorProposals[_proposalNumber].newCreator;
    }else if (changeCreatorProposals[_proposalNumber].creatorNumber == 3){
      creator3 = changeCreatorProposals[_proposalNumber].newCreator;
    }else if (changeCreatorProposals[_proposalNumber].creatorNumber == 4){
      creator4 = changeCreatorProposals[_proposalNumber].newCreator;
    }else if (changeCreatorProposals[_proposalNumber].creatorNumber == 5){
      creator5 = changeCreatorProposals[_proposalNumber].newCreator;
    }
  }

}
