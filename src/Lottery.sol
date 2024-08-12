// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Lottery {
    struct Ticket {
        address owner;
        uint256 number;
    }

    Ticket[] public tickets;

    // ticket 가격은 0.1로 설정 판매기간은 24시간으로 설정
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

    //티켓의 가격이 0.1 ether가 아닐경우 에러를 발생시킨다.
    //판매기간은 24시간 이내여야한다.
    //동일한 구매자는 동일한 티켓을 구매할 수 없다.
    function buy(uint number) public payable {
        require(msg.value == ticketPrice, "Lottery: invalid ticket price");
        require(block.timestamp < drawTime, "Lottery: sell phase ended");
        for (uint i = 0; i < tickets.length; i++) {
            require(tickets[i].owner != msg.sender, "Lottery: duplicate ticket");
        }
        prize += msg.value;
        tickets.push(Ticket(msg.sender, number));
    }

    //티켓판매 24시간이전에는 에러를 발생시킨다.
    //이미 추첨이 된 경우 에러를 발생시킨다.
    function draw() public payable{
        require(block.timestamp > 24 hours, "Lottery: draw phase not started yet");
        require(!isDrawn, "Lottery: already drawn");
        winningNumber();
        isDrawn = true;
    }

    //isDrawn이 false인 경우 에러를 발생시킨다.(추첨이 진행되지 않은 상태에서 claim할 경우)
    function claim() public {
        require(isDrawn, "Lottery: draw not completed");

        //중복 당첨 일 경우 당첨금을 나누기 위해 당첨자의 수를 센다.
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
            if(isWinner){
                //당첨자 일 경우 당첨금을 당첨자 수로 나누어 지급한다.
                uint256 prizeShare = prize / winnerCount;

                (bool success, ) = msg.sender.call{value: prizeShare}("");
            }else{
                (bool success, ) = msg.sender.call{value: 0}("");
            }
        } else {        
            if(winnerCount == 0){
                (bool success, ) = msg.sender.call{value: 0}("");
            }
            //다음 게임을 위해 초기화한다.
            delete tickets;
            isDrawn = false;
            sellPhaseStart = block.timestamp;
            drawTime = sellPhaseStart + sellPhase;
        }
    }
    
    function winningNumber() public returns (uint16) {
        winNumber = uint16(uint256(keccak256(abi.encodePacked(block.timestamp + 24 hours))));
        return winNumber;
    }

    receive() external payable {
    }
}