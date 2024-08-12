// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Lottery {
    struct Ticket {
        address owner;
        uint256 number;
    }

    Ticket[] public tickets;

    uint256 public constant ticketPrice = 0.1 ether;
    uint256 public constant sellPhase = 24 hours;
    uint256 public prize;
    uint256 public sellPhaseStart;
    uint256 public drawTime;
    uint16 public winNumber;
    bool public isDrawn;

    constructor() {
        sellPhaseStart = block.timestamp;
        drawTime = sellPhaseStart + sellPhase;
    }

    function buy(uint number) public payable {
        require(msg.value == ticketPrice, "Lottery: invalid ticket price");
        require(block.timestamp < drawTime, "Lottery: sell phase ended");
        for (uint i = 0; i < tickets.length; i++) {
            require(tickets[i].owner != msg.sender, "Lottery: duplicate ticket");
        }
        prize += msg.value;
        tickets.push(Ticket(msg.sender, number));
    }

    function draw() public payable{
        require(block.timestamp > 24 hours, "Lottery: draw phase not started yet");
        require(!isDrawn, "Lottery: already drawn");
        winningNumber();
        isDrawn = true;
    }

    function claim() public {
        require(isDrawn, "Lottery: draw not completed");

        uint256 winnerCount = 0;

        for (uint i = 0; i < tickets.length; i++) {
            if (tickets[i].number == winNumber) {
                winnerCount++;
            }
        }

        if (winnerCount > 0) {
            bool isWinner = false;
            for (uint i = 0; i < tickets.length; i++) {
                if (tickets[i].owner == msg.sender && tickets[i].number == winNumber) {
                    isWinner = true;
                    break;
                }
            }

            require(isWinner, "Lottery: not winning ticket");

            uint256 prizeShare = prize / winnerCount;

            (bool success, ) = msg.sender.call{value: prizeShare}("");
            require(success, "Lottery: transfer failed");
        } else {
            delete tickets;
            isDrawn = false;
            sellPhaseStart = block.timestamp;
            drawTime = sellPhaseStart + sellPhase;
        }
    }

    function getWinningTicket() internal view returns (Ticket memory) {
        for (uint i = 0; i < tickets.length; i++) {
            if (tickets[i].number == winNumber) {
                return tickets[i];
            }
        }
        revert("Lottery: No winning ticket found");
    }

    function winningNumber() public returns (uint16) {
        winNumber = uint16(uint256(keccak256(abi.encodePacked(block.timestamp + 24 hours))) % 10000);
        return winNumber;
    }

    receive() external payable {
    }
}