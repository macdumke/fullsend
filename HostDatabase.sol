pragma solidity ^0.4.24;
/** @title Host Database. */
contract HostDatabase{
  mapping (address => mapping(bytes32 => uint8)) hostDatabase;

  /** @dev Adds a person to the host's free friends list.
    * @param _identification Name of person added to list.
    */
  function addFree(string _identification) public {
    hostDatabase[tx.origin][keccak256(abi.encodePacked(_identification))] = 1;
  }

  /** @dev Adds a person to the host's verified friends list.
      * @param _identification Name of person added to list.
      */
  function addVerified(string _identification) public {
    hostDatabase[tx.origin][keccak256(abi.encodePacked(_identification))] = 2;
  }

  /** @dev Removes a person from the host's free friends list.
    * @param _identification Name of person removed from list.
    */
  function remove(string _identification) public {
    hostDatabase[tx.origin][keccak256(abi.encodePacked(_identification))] = 0;
  }

  /** @dev Returns if person gets in free for hosts' parties.
    * @param _identification Name of person potentially on the free list.
    * @param _host Address of host.
    * @return uint8 Status of person.
      */
  function status(string _identification, address _host) public view returns (uint8) {
    return hostDatabase[_host][keccak256(abi.encodePacked(_identification))];
  }

}
