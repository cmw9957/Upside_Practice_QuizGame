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

    address public owner;

    mapping(uint => Quiz_item) public quizItems;

    mapping(address => uint256)[] public bets;
    uint public vault_balance;

    mapping(address => uint) public round;

    mapping(uint => string) public answer;

    mapping(address => mapping(uint => bool)) complete;

    constructor () {
        Quiz_item memory q;
        q.id = 1;
        q.question = "1+1=?";
        q.answer = "2";
        q.min_bet = 1 ether;
        q.max_bet = 2 ether;
        owner = msg.sender;
        round[msg.sender] = 1;
        
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
        require(msg.sender == owner, "You're not admin.");
        answer[q.id] = q.answer;
        q.answer = "";
        quizItems[q.id] = q;
        bets.push();
    }

    function getAnswer(uint quizId) public view quizExists(quizId) returns (string memory){
        return answer[quizId];
    }

    function getQuiz(uint quizId) public view quizExists(quizId) returns (Quiz_item memory) {
        return quizItems[quizId];
    }

    function getQuizNum() public view returns (uint){
        return round[msg.sender];
    }
    
    function betToPlay(uint quizId) public payable quizExists(quizId) validBetAmount(quizId){
        bets[quizId-1][msg.sender] += msg.value;
    }

    function solveQuiz(uint quizId, string memory ans) public quizExists(quizId) returns (bool) {
        require(bets[quizId-1][msg.sender] > 0, "Bet first.");
        address sender = msg.sender;
        if (keccak256(abi.encode(answer[quizId])) == keccak256(abi.encode(ans))) {
            round[sender] += 1;
            complete[sender][quizId] = true;
            return true;
        } else {
            vault_balance += bets[quizId-1][sender];
            bets[quizId-1][sender] = 0;
            return false;
        }
    }

    function claim() public {
        uint256 reward = 0;
        address recipient = msg.sender;
        for (uint i = 1;i <= bets.length;i++) {
            if (complete[recipient][i]) {
                reward += bets[i-1][recipient];
            }
        }

        require(reward * 2 <= vault_balance, "Vault balance is not enough...");
        
        payable(recipient).transfer(reward * 2);
        vault_balance -= reward * 2;
    }

    receive() external payable {
        vault_balance += msg.value;
    }

}
