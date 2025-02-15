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
    uint public vault_balance;

    mapping(uint => Quiz_item) public quizItems;
    mapping(address => uint256)[] public bets;
    mapping(address => uint) public round;
    mapping(uint => bytes32) private answer;
    mapping(address => mapping(uint => bool)) public quizComplete;

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

    modifier onlyOwner() {
        require(msg.sender == owner, "You're not owner.");
        _;
    }

    modifier quizExists(uint quizId) {
        require(quizItems[quizId].id != 0, "Quiz with this ID not exists.");
        _;
    }

    modifier validBetAmount(uint quizId) {
        require(msg.value >= quizItems[quizId].min_bet && msg.value <= quizItems[quizId].max_bet, "Invalid bet amount.");
        _;
    }

    modifier checkQuizId(uint quizId) {
        require(quizId == 0, "Quiz with this ID already exists or must be greater than 0.");
        _;
    }

    function addQuiz(Quiz_item memory q) public onlyOwner() checkQuizId(quizItems[q.id].id) {
        answer[q.id] = keccak256(abi.encode(q.answer));
        q.answer = "";
        quizItems[q.id] = q;
        bets.push();
    }

    function getAnswer(uint quizId) public view quizExists(quizId) returns (bytes32){
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

    function solveQuiz(uint quizId, bytes32 ans) public quizExists(quizId) returns (bool) {
        require(bets[quizId-1][msg.sender] > 0, "Bet first.");
        address sender = msg.sender;
        if (answer[quizId] == ans) {
            round[sender] += 1;
            quizComplete[sender][quizId] = true;
            return true;
        } else {
            vault_balance += bets[quizId-1][sender];
            bets[quizId-1][sender] = 0;
            return false;
        }
    }

    function claim() public {
        uint256 reward = 0;
        uint256 betsLength = bets.length;
        for (uint i = 0;i < betsLength;i++) {
            if (quizComplete[msg.sender][i+1]) {
                reward += bets[i][msg.sender];
            }
        }

        require(reward * 2 <= vault_balance, "Vault balance is not enough...");
        
        vault_balance -= reward * 2;
        payable(msg.sender).transfer(reward * 2);
    }

    receive() external payable {
        vault_balance += msg.value;
    }

}
