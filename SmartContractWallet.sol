// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.22;

contract SmartContractWallet {

    address payable public owner;

    mapping(address=>uint) public allowance;
    mapping(address=>bool) public addressAllowed;

    mapping(address => bool) public guardians;

    address payable nextOwner;
    mapping(address=>mapping(address=>bool)) nextOwnerGuardianVotedBool;
    uint guardiansResetCount;
    uint public constant confirmationsFromGuardiansForReset = 3; 

    constructor(){
        owner = payable(msg.sender);
    }

    function setGuardian(address _guardian, bool _isGuardian) public{
        require(msg.sender==owner, "You are not the owner, aborting");
        guardians[_guardian] = _isGuardian;
    }

    function proposeNewOwner(address payable _newOwner) public{
        require(guardians[msg.sender], "You are not a guardian of this wallet, aborting");
        require(nextOwnerGuardianVotedBool[_newOwner][msg.sender] == false, "You already voted, aborting");
        if(_newOwner != nextOwner){
            nextOwner = _newOwner;
            guardiansResetCount = 0;
        }
        guardiansResetCount++;
        if(guardiansResetCount>=confirmationsFromGuardiansForReset){
            owner = nextOwner;
            nextOwner=payable(address(0));
            guardiansResetCount = 0;
        }
    }

    receive() external payable {}

    function setAllowance(address _for, uint _amount) public{
        require(msg.sender==owner, "You are not the owner, aborting");

        allowance[_for] = _amount;
        addressAllowed[_for] = _amount>0;
    
    }



    function transfer(address payable _to, uint _amount, bytes memory _payload) public returns(bytes memory) {
        //require(msg.sender == owner, "You are not the owner, aborting");
        if(msg.sender!=owner){
            require(addressAllowed[msg.sender], "You are not allowed to send anything from this smart contract, aborting");
            require(allowance[msg.sender] >= _amount, "You are trying to send more then you are allowed to, aborting");

            allowance[msg.sender] -= _amount;
        }
        require(owner.balance >= _amount, "Not enough funds, aborting");
        (bool success, bytes memory returnData)=_to.call{value:_amount}(_payload);
        require(success,"Aborting, call was not successfull");
        return  returnData;
    }

}
contract Consumer{
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    function deposit() public payable {}
    
}