// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Quiz{
    struct Quiz_item {
      uint id;
      string question;
      string answer;
      uint min_bet;
      uint max_bet;
    }

    mapping(uint => Quiz_item) public quizItems;

    mapping(address => uint256)[] public bets;
    uint public vault_balance;

    uint currentQuizNum = 1;

    constructor () {
        Quiz_item memory q;
        q.id = 1;
        q.question = "1+1=?";
        q.answer = "2";
        q.min_bet = 1 ether;
        q.max_bet = 2 ether;
        addQuiz(q);
    }

    modifier quizExists(uint quizId) {
        require(quizItems[quizId].id != 0, "Quiz with this ID not exists.");
        _;
    }

    modifier validBetAmount(uint quizId) {
        require(msg.value >= quizItems[quizId].min_bet && msg.value <= quizItems[quizId].max_bet, "Invalid bet amount.");
        _;
    }

    function addQuiz(Quiz_item memory q) public {
        require(quizItems[q.id].id == 0, "Quiz with this ID already exists.");
        require(q.id > 0, "Invalid Quiz id.");
        quizItems[q.id] = q;
        bets.push();
    }

    function getAnswer(uint quizId) public view quizExists(quizId) returns (string memory){
        return quizItems[quizId].answer;
    }

    function getQuiz(uint quizId) public view quizExists(quizId) returns (Quiz_item memory) {
        return quizItems[quizId];
    }

    function getQuizNum() public view returns (uint){
        return currentQuizNum;
    }
    
    function betToPlay(uint quizId) public payable quizExists(quizId) validBetAmount(quizId){
        bets[quizId-1][msg.sender] += msg.value;
    }

    function solveQuiz(uint quizId, string memory ans) public returns (bool) {
    }

    function claim() public {
    }

}
