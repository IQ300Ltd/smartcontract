pragma solidity ^0.4.11;
import 'zeppelin-solidity/contracts/token/StandardToken.sol';
import './Active.sol';

contract Iq300Token is StandardToken, Active {

    string public name;
    string public symbol;
    uint public decimals = 2;
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

    event ParticipantJoined(
        address indexed _addr,
        uint _itaskId,
        uint _userId
    );

    event TaskPaid(
        address indexed _addr,
        uint _itaskId,
        uint _userId,
        uint256 _amount
    );

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

    function addParticipant(
        address _addr,
        uint _userId,
        uint _taskId,
        uint256 _amount
    ) onlyOwner onlyActive returns (bool) {
        require(balances[this] - _amount - reserved >= 0);
        var executor = subExecutors[_addr];
        if (executor.userId == 0) {
            subExecutors[_addr] = Participant({
                userId: _userId,
                addr: _addr,
                paidAmount: 0,
                reservedAmount: 0
            });
        }
        executor.reservedAmount += _amount;
        reserved += _amount;
        require(executor.payments[_taskId].createdAt == 0);
        executor.payments[_taskId] = TaskPayment({
            amount: _amount,
            isPaid: false,
            createdAt: now
        });
        ParticipantJoined(_addr, _userId, _taskId);
        return true;
    }

    function getParticipantPaidAmount(address _addr) returns (uint256) {
        return subExecutors[_addr].paidAmount;
    }

    function getParticipantReservedAmount(address _addr) returns (uint256) {
        return subExecutors[_addr].reservedAmount;
    }

    function payForTask(address _addr, uint taskId) onlyOwner onlyActive returns (bool) {
        var participant = subExecutors[_addr];
        require(participant.userId != 0);
        var payment = participant.payments[taskId];
        require(payment.createdAt != 0);
        require(payment.isPaid == false);
        if (payment.amount == 0) {
            return false;
        }
        participant.reservedAmount -= payment.amount;
        participant.paidAmount += payment.amount;
        payment.isPaid = true;
        reserved -= payment.amount;
        if (transferFromOwner(_addr, payment.amount)) {
            TaskPaid(_addr, taskId, participant.userId, payment.amount);
            return true;
        } else {
            return false;
        }
    }

    function transferFromOwner(address _addr, uint256 _amount) onlyOwner onlyActive returns (bool) {
        require(balances[this] >= _amount);
        balances[this] = balances[this].sub(_amount);
        balances[_addr] = balances[_addr].add(_amount);
        return true;
    }

     function close() onlyOwner onlyActive  {
         deactivate();
         if (balances[this] == 0) {
             return;
         }
         if (mainExecutor.userId == 0) {
             balances[owner] = balances[this];
         }
         else {
             balances[mainExecutor.addr] = balances[this];
         }
         balances[this] = 0;
     }
}