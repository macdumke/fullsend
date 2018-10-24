pragma solidity ^0.4.24;
/** @title Host Database. */
contract HostDatabase {

  function addFree(string) public {}

  function addVerified(string) public {}

  function remove(string) public {}

  function status(string, address) public view returns (uint8) {}
}

/** @title Creators Database. */
contract Creators{
  function creator1() public returns (address) {}

  function creator2() public returns (address) {}

  function creator3() public returns (address) {}

  function creator4() public returns (address) {}

  function creator5() public returns (address) {}

  function createProposal(uint256, uint8, address) public {}

  function approveProposal(uint256) public {}

  function change(uint256) public {}

}

/** @title Full Send. */
contract FullSend{
  //modifiers
  /** @dev Checks if party has ended.
      * @param _partyName Name of party.
      */
  modifier auctionEnded(bytes32 _partyName){
    require(allParties[_partyName].endingTime + 30 seconds < block.timestamp);
    _;
  }

  /** @dev Checks if ticket exists for a certain party.
        * @param _partyName Name of party.
        * @param _ticketNumber Ticket number.
        */
  modifier isTicket(bytes32 _partyName, uint32 _ticketNumber){
    require(_ticketNumber < allParties[_partyName].numTickets);
    _;
  }

  /** @dev Checks if message sender is a creator.
      */
  modifier onlyCreator{
    require(msg.sender == c.creator1() || msg.sender == c.creator2() || msg.sender == c.creator3() || msg.sender == c.creator4() || msg.sender == c.creator5());
    _;
  }

  // data
  address public charity;
  uint256 public creatorBalance = 0;
  uint256 public charityBalance = 0;
  uint32 public percentToCharity = 10;
  uint32 public percentToHost = 80;
  uint32 public percentToCreator = 10;
  uint256 public percentageTime = 0;
  uint256 public charityTime = 0;
  uint256 public killTime = 0;
  HostDatabase hdb;
  Creators c;

  struct Party{
    address host;
    uint256 hostBalance;
    uint256 minPrice;
    uint256 endingTime;
    uint32 numTickets;
    uint32 percentExtra;
    uint32 numGenTickets;
    uint32 genTicketProgress;
    uint256 genTicketPrice;
    bool verified;
    mapping (uint32 => Bid) currentBids;
    mapping (bytes32 => bool) genTicketHolders;
  }

  struct Bid{
    address bidder;
    uint256 currentBid;
    mapping (address => uint256) allBids;
    bytes32 identification;
    bool claimed;
  }

  mapping (bytes32 => Party) allParties;
  mapping (bytes32 => uint256) organizations;

  /** @dev Constructor that sets the address for charity and creator.
      * @param _charity Charity address.
      * @param _hdb HostDatabase contract address.
      * @param _c Creators contract address.
      */
  constructor(address _charity, address _hdb, address _c) public{
    charity = _charity;
    hdb = HostDatabase(_hdb);
    c = Creators(_c);
  }

  //state changing functions
  /** @dev Adds a person to the host's free friends list.
    * @param _identification Name of person added to list.
    */
  function addFreeFriendToHostDatabase(string _identification) public {
    hdb.addFree(_identification);
  }

  /** @dev Adds a person to the host's verified friends list.
      * @param _identification Name of person added to list.
      */
  function addVerifiedFriendToHostDatabase(string _identification) public {
    hdb.addVerified(_identification);
  }

  /** @dev Removes a person from the host's free friends list.
    * @param _identification Name of person removed from list.
    */
  function removeFromHostDatabase(string _identification) public {
    hdb.remove(_identification);
  }
  /** @dev Creates a party and adds it to allParties mapping.
      * @param _partyName Name of party.
      * @param _minPrice Minimum price of auction tickets.
      * @param _numTickets Number of tickets being auctioned off.
      * @param _seconds Number of seconds beyond block.timestamp, until the auction ends.
      * @param _numGenTickets Number of fixed price tickets.
      * @param _genTicketPrice Price of fixed price tickets.
      * @param _percentExtra Percentage beyond base percentage that the host is giving to charity.
      * @param _verified If only verified users are allowed to bid on the party.
      */
  function createParty(string _partyName, uint256 _minPrice, uint32 _numTickets, uint32 _percentExtra, uint256 _seconds,  uint32 _numGenTickets, uint256 _genTicketPrice, bool _verified) public {
    require(_percentExtra < percentToHost && allParties[keccak256(abi.encodePacked(_partyName))].host == 0);
    allParties[keccak256(abi.encodePacked(_partyName))] = Party(msg.sender, 0, _minPrice, block.timestamp + _seconds, _numTickets, _percentExtra, _numGenTickets, 0, _genTicketPrice, _verified);
  }

  /** @dev Bids on a ticket from a party.
      * @param _partyName Name of party.
      * @param _ticketNumber Ticket number.
      * @param _identification Name of person attending party.
      */
  function bid(string _partyName, uint32 _ticketNumber, string _identification) public isTicket(keccak256(abi.encodePacked(_partyName)), _ticketNumber) payable{
    bytes32 partyName = keccak256(abi.encodePacked(_partyName));
    require(allParties[partyName].endingTime > block.timestamp && msg.value + allParties[partyName].currentBids[_ticketNumber].allBids[msg.sender] > allParties[partyName].minPrice && msg.value + allParties[partyName].currentBids[_ticketNumber].allBids[msg.sender] > allParties[partyName].currentBids[_ticketNumber].currentBid && (!(allParties[partyName].verified) || hdb.status(_identification, allParties[partyName].host) == 2));
    allParties[partyName].currentBids[_ticketNumber].bidder = msg.sender;
    allParties[partyName].currentBids[_ticketNumber].currentBid = msg.value + allParties[partyName].currentBids[_ticketNumber].allBids[msg.sender];
    allParties[partyName].currentBids[_ticketNumber].allBids[msg.sender] += msg.value;
    allParties[partyName].currentBids[_ticketNumber].identification = keccak256(abi.encodePacked(_identification));
  }


  /** @dev Withdraw a failed bid after the auction ends and potentially give some to charity.
      * @ param _partyName Name of party.
      * @param _ticketNumber Ticket number.
      * @param _percentToCharity Percentage given to charity.
      */
  function withdrawBid(string _partyName, uint32 _ticketNumber, uint256 _percentToCharity) public auctionEnded(keccak256(abi.encodePacked(_partyName))) isTicket(keccak256(abi.encodePacked(_partyName)), _ticketNumber){
    bytes32 partyName = keccak256(abi.encodePacked(_partyName));
    uint256 withdrawAmount = allParties[partyName].currentBids[_ticketNumber].allBids[msg.sender];
    allParties[partyName].currentBids[_ticketNumber].allBids[msg.sender] = 0;
    require(_percentToCharity <= 100 && allParties[partyName].currentBids[_ticketNumber].bidder != msg.sender && withdrawAmount > 0);
    msg.sender.transfer(withdrawAmount*(100-_percentToCharity)/100);
    charityBalance += ((withdrawAmount*_percentToCharity)/100);
  }

  /** @dev Claim spot on highest bid after auction ends.
      * @ param _partyName Name of party.
      * @param _ticketNumber Ticket number.
      */
  function claimSpot(string _partyName, uint32 _ticketNumber) public auctionEnded(keccak256(abi.encodePacked(_partyName))) isTicket(keccak256(abi.encodePacked(_partyName)), _ticketNumber){
    bytes32 partyName = keccak256(abi.encodePacked(_partyName));
    uint256 claimAmount = allParties[partyName].currentBids[_ticketNumber].allBids[msg.sender];
    allParties[partyName].currentBids[_ticketNumber].allBids[msg.sender] = 0;
    require(claimAmount > 0 && msg.sender == allParties[partyName].currentBids[_ticketNumber].bidder);
    charityBalance += (claimAmount*(allParties[partyName].percentExtra+percentToCharity))/100;
    allParties[partyName].hostBalance += (claimAmount*(percentToHost-allParties[partyName].percentExtra))/100;
    creatorBalance += (claimAmount*percentToCreator)/100;
    allParties[partyName].currentBids[_ticketNumber].claimed = true;
  }

  /** @dev Buy a fixed price ticket.
      * @ param _partyName Name of party.
      * @param _identification Name of person attending party.
      */
  function buy(string _partyName, string _identification) public payable{
    bytes32 partyName = keccak256(abi.encodePacked(_partyName));
    require(allParties[partyName].genTicketProgress++ < allParties[partyName].numGenTickets && msg.value >= allParties[partyName].genTicketPrice);
    charityBalance += (msg.value*(allParties[partyName].percentExtra+percentToCharity))/100;
    allParties[partyName].hostBalance += (msg.value*(percentToHost-allParties[partyName].percentExtra))/100;
    creatorBalance += (msg.value*percentToCreator)/100;
    allParties[partyName].genTicketHolders[keccak256(abi.encodePacked(_identification))] = true;
  }

  /** @dev Host withdraws funds from party.
      * @ param _partyName Name of party.
      */
  function hostWithdraw(string _partyName) public auctionEnded(keccak256(abi.encodePacked(_partyName))){
    bytes32 partyName = keccak256(abi.encodePacked(_partyName));
    require(msg.sender == allParties[partyName].host);
    uint256 hostWithdrawAmount = allParties[partyName].hostBalance;
    allParties[partyName].hostBalance = 0;
    require(hostWithdrawAmount > 0);
    msg.sender.transfer(hostWithdrawAmount);
  }

  /** @dev Host withdraws funds from party.
      * @ param _partyName Name of party.
      */
  function hostWithdrawOrganizations(string _partyName, string _localChapter, string _national, string _school) public auctionEnded(keccak256(abi.encodePacked(_partyName))){
    bytes32 partyName = keccak256(abi.encodePacked(_partyName));
    require(msg.sender == allParties[partyName].host);
    uint256 hostWithdrawAmount = allParties[partyName].hostBalance;
    allParties[partyName].hostBalance = 0;
    uint256 amountRaised = hostWithdrawAmount * ((percentToCharity+allParties[partyName].percentExtra)/(percentToHost-allParties[partyName].percentExtra));
    bytes32 localChapter = keccak256(abi.encodePacked(_localChapter));
    bytes32 national = keccak256(abi.encodePacked(_national));
    bytes32 school = keccak256(abi.encodePacked(_school));
    require(hostWithdrawAmount > 0 && localChapter != national && localChapter != school && school != national);
    organizations[localChapter] += amountRaised;
    organizations[national] += amountRaised;
    organizations[school] += amountRaised;
    msg.sender.transfer(hostWithdrawAmount);
  }

  /** @dev Charity withdraws funds.
      */
  function charityWithdraw() public {
    require(msg.sender == charity);
    uint256 charityWithdrawAmount = charityBalance;
    charityBalance = 0;
    require(charityWithdrawAmount > 0);
    msg.sender.transfer(charityWithdrawAmount);
  }

  /** @dev Creator withdraws funds.
      */
  function creatorWithdraw() public onlyCreator{
    uint256 creatorWithdrawAmount = creatorBalance;
    creatorBalance = 0;
    require(creatorWithdrawAmount > 0);
    msg.sender.transfer(creatorWithdrawAmount);
  }

  /** @dev Initiate kill contract timer.
      */
  function initiateTimer(uint8 _timer) public onlyCreator{
    if(_timer == 1){
      percentageTime = block.timestamp;
    }else if(_timer == 2){
      charityTime = block.timestamp;
    }else if(_timer == 3){
      killTime = block.timestamp;
    }
  }

  /** @dev Reset a timer.
      */
  function resetTimer(uint8 _timer) public onlyCreator{
    if(_timer == 1){
      percentageTime = 0;
    }else if(_timer == 2){
      charityTime = 0;
    }else if(_timer == 3){
      killTime = 0;
    }
  }

  /** @dev Initiate a change to contract settings.
    * @ param _change Change to be made.
    * @param _percentToCharity Percent to charity.
    * @param _percentToHost Percent to host.
    * @param _percentToCreator Percent to creator.
    * @param _charity Address of new charity.
    */
  function initiateChange(uint8 _change, uint32 _percentToCharity, uint32 _percentToHost, uint32 _percentToCreator, address _charity) public onlyCreator{
    if(_change == 1){
      require(_percentToCharity + _percentToHost + _percentToCreator == 100 && percentageTime != 0 && block.timestamp > percentageTime + 2 weeks);
      percentToCharity = _percentToCharity;
      percentToHost = _percentToHost;
      percentToCreator = _percentToCreator;
    }else if(_change == 2){
      require(charityTime != 0 && block.timestamp > charityTime + 2 weeks);
      charity = _charity;
    }else if(_change == 3){
      require(killTime != 0 && block.timestamp > killTime + 2 weeks);
      selfdestruct(c.creator1());
    }
  }

  /** @dev Create change creator proposal.
        * @param _proposalNumber Proposal number.
        * @param _creatorNumber Creator number.
        * @param _newCreator New creator address.
        */
  function createChangeCreatorProposal(uint256 _proposalNumber, uint8 _creatorNumber, address _newCreator) public {
    c.createProposal(_proposalNumber, _creatorNumber, _newCreator);
  }

  /** @dev Creator approves a change creator proposal.
        * @param _proposalNumber Proposal number.
        */
  function approveChangeCreatorProposal(uint256 _proposalNumber) public {
    c.approveProposal(_proposalNumber);
  }

  /** @dev Change creator address.
        * @param _proposalNumber Proposal number.
        */
  function changeCreator(uint256 _proposalNumber) public {
    c.change(_proposalNumber);
  }

  //getter functions
  /** @dev Returns the invitation type of person.
      * @ param _partyName Name of party.
      * @param _ticketNumber Ticket number.
      * @param _identification Name of person potentially attending the party.
      * @return uint256 Invitation status.
      */
  function isInvited(string _partyName, uint32 _ticketNumber, string _identification) public view returns(uint256){
    bytes32 partyName = keccak256(abi.encodePacked(_partyName));
    bytes32 identification = keccak256(abi.encodePacked(_identification));
    if(allParties[partyName].currentBids[_ticketNumber].identification == identification && allParties[partyName].currentBids[_ticketNumber].claimed == true){
      return 3;
    }else if(hdb.status(_identification, allParties[partyName].host) == 1){
      return 2;
    }else{
      if(allParties[partyName].genTicketHolders[identification] == true){
        return 1;
      }
      return 4;
    }
  }

  /** @dev Returns party uint256 value.
    * @param _partyName Party name.
    * @param _value Value to return.
    * @param _ticketNumber TicketNumber.
    * @return uint256 Party value.
    */
  function getPartyValue256(string _partyName, uint8 _value, uint32 _ticketNumber) public view returns(uint256){
    bytes32 partyName = keccak256(abi.encodePacked(_partyName));
    if(_value == 1){
      return allParties[partyName].minPrice;
    }else if(_value == 2){
      return allParties[partyName].currentBids[_ticketNumber].currentBid;
    }else if(_value == 3){
      return allParties[partyName].endingTime;
    }else if(_value == 4){
      return allParties[partyName].currentBids[_ticketNumber].allBids[msg.sender];
    }else if(_value == 5){
      return allParties[partyName].genTicketPrice;
    }else if(_value == 6){
      return allParties[partyName].hostBalance;
    }else if(_value == 7){
      return organizations[keccak256(abi.encodePacked(_partyName))];
    }

  }

  /** @dev Returns party uint32 value.
    * @param _partyName Party name.
    * @param _value Value to return.
    * @return uint32 Party value.
    */
  function getPartyValue32(string _partyName, uint8 _value) public view returns(uint32){
    bytes32 partyName = keccak256(abi.encodePacked(_partyName));
    if(_value == 1){
      return allParties[partyName].percentExtra + percentToCharity;
    }else if(_value == 2){
      return percentToHost - allParties[partyName].percentExtra;
    }else if(_value == 3){
      return allParties[partyName].numTickets;
    }else if(_value == 4){
      return allParties[partyName].numGenTickets;
    }else if(_value == 5){
      return allParties[partyName].genTicketProgress;
    }
  }

  /** @dev Returns party bool value.
    * @param _partyName Party name.
    * @param _value Value to return.
    * @return bool Party value.
    */
  function getPartyValueBool(string _partyName, uint8 _value) public view returns(bool){
    bytes32 partyName = keccak256(abi.encodePacked(_partyName));
    if(_value == 1){
      return allParties[partyName].verified;
    }else if(_value == 2){
      if(block.timestamp > allParties[partyName].endingTime + 30 seconds){
        return true;
      }else{
        return false;
      }
    }else if(_value == 3){
      if(allParties[partyName].endingTime != 0){
        return true;
      }else{
        return false;
      }
    }
  }

  /** @dev Returns party bool value.
    * @param _partyName Party name.
    * @return address Address of host of party.
    */
  function getPartyHost(string _partyName) public view returns(address){
    return allParties[keccak256(abi.encodePacked(_partyName))].host;
  }

   /** @dev Returns if person gets in free for hosts' parties.
    * @param _identification Name of person potentially on the free list.
    * @return uint8 Status of person.
      */
  function getFriendStatus(string _identification) public view returns (uint8) {
    return hdb.status(_identification, msg.sender);
  }

}
