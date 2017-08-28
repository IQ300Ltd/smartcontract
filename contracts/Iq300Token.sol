pragma solidity ^0.4.11;
import 'zeppelin-solidity/contracts/token/StandardToken.sol';
import './Active.sol';

contract Iq300Token is StandardToken, Active {

    string public name;
    string public symbol;
    uint public decimals = 2;
    bool public closed = false;
    uint public projectId;

    uint256 public reserved;

    struct TaskPayment {
       uint256 amount;
       bool isPaid;
       uint createdAt;
    }
    struct Participant {
      uint userId;
      address addr;
      uint256 paidAmount;
      uint256 reservedAmount;
      mapping (uint => TaskPayment) payments;
    }

    Participant public mainCustomer;
    Participant public mainExecutor;
    mapping (address => Participant) public subExecutors;

    function Iq300Token(string _name, string _symbol, uint initialSupply, uint _projectId) {
        name = _name;
        symbol = _symbol;
        totalSupply = initialSupply;
        balances[this] = initialSupply;
        projectId = _projectId;
    }

    function setMainCustomer(address _addr, uint userId) onlyOwner onlyActive {
        mainCustomer = Participant({userId: userId, addr: _addr, paidAmount: 0, reservedAmount: 0});
    }

    function setMainExecutor(address _addr, uint userId) onlyOwner onlyActive {
        mainExecutor = Participant({userId: userId, addr: _addr, paidAmount: 0, reservedAmount: 0});
    }

    function addParticipant(address _addr, uint _userId, uint _taskId, uint _amount) onlyOwner onlyActive {
        require(balances[this] - _amount - reserved >= 0);
        if (subExecutors[_addr].userId == 0) {
            subExecutors[_addr] = Participant({userId: _userId, addr: _addr, paidAmount: 0, reservedAmount: 0});
        }
        subExecutors[_addr].reservedAmount += _amount;
        reserved += _amount;
        require(subExecutors[_addr].payments[_taskId].createdAt == 0);
        subExecutors[_addr].payments[_taskId] = TaskPayment({amount: _amount, isPaid: false, createdAt: now});
    }

    function getParticipantPaidAmount(address _addr) returns (uint256) {
        return subExecutors[_addr].paidAmount;
    }

    function getParticipantReservedAmount(address _addr) returns (uint256) {
        return subExecutors[_addr].reservedAmount;
    }

    function payForTask(address _addr, uint taskId) onlyOwner onlyActive {
        require(subExecutors[_addr].userId != 0);
        var participant = subExecutors[_addr];
        require(participant.payments[taskId].createdAt != 0);
        require(participant.payments[taskId].isPaid == false);
        var payment = subExecutors[_addr].payments[taskId];
        if (payment.amount == 0) {
            return;
        }
        participant.reservedAmount -= payment.amount;
        participant.paidAmount += payment.amount;
        payment.isPaid = true;
        reserved -= payment.amount;
        transfer(_addr, payment.amount);
    }

     function close() onlyOwner onlyActive  {
         require (reserved == 0);
         deactivate();
         if (balances[this] == 0) {
             return;
         }
         if (mainExecutor.userId == 0) {
             transfer(owner, balances[this]);
         }
         else {
             transfer(mainExecutor.addr, balances[this]);
         }
     }
}