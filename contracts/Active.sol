pragma solidity ^0.4.11;
import './Ownable.sol';


contract Active is Ownable {
    bool public active = true;

    modifier onlyActive() {
        require(active == true);
        _;
    }

    function deactivate() onlyActive onlyOwner {
        active = false;
    }
}
