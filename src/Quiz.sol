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

    mapping(uint => Quiz_item) public quizItems; // Quiz_item의 id 값 기준으로 mapping
    mapping(address => uint256)[] public bets; // address마다 각 round bet 금액 저장
    mapping(address => uint) public round; // address마다 현재 round 저장(순차적으로 증가)
    mapping(uint => bytes32) private answer; // Quiz_item 구조체의 answer를 따로 hashing
    mapping(address => mapping(uint => bool)) public quizComplete; // address마다 round별 quiz 성공 여부 저장

    constructor () {
        // init quiz 생성
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

    // only owner 권한
    modifier onlyOwner() {
        require(msg.sender == owner, "You're not owner.");
        _;
    }

    // check quiz exist
    modifier quizExists(uint quizId) {
        require(quizItems[quizId].id != 0, "Quiz with this ID not exists.");
        _;
    }

    // check bet amount range
    modifier validBetAmount(uint quizId) {
        require(msg.value >= quizItems[quizId].min_bet && msg.value <= quizItems[quizId].max_bet, "Invalid bet amount.");
        _;
    }

    // check Quiz_item empty
    modifier checkQuizId(uint quizId) {
        require(quizId == 0, "Quiz with this ID already exists.");
        _;
    }

    // owner만의 Quiz_item을 quizItems에 추가하는 함수. answer는 따로 암호화 후 저장. bets는 quiz 추가될 때마다 push
    function addQuiz(Quiz_item memory q) public onlyOwner() checkQuizId(quizItems[q.id].id) {
        answer[q.id] = keccak256(abi.encode(q.answer));
        q.answer = "";
        quizItems[q.id] = q;
        bets.push();
    }

    // 암호화된 answer return
    function getAnswer(uint quizId) public view quizExists(quizId) returns (bytes32){
        return answer[quizId];
    }

    // quizId에 해당하는 quiz return
    function getQuiz(uint quizId) public view quizExists(quizId) returns (Quiz_item memory) {
        return quizItems[quizId];
    }

    // 사용자마다의 현재 round 값 return
    function getQuizNum() public view returns (uint){
        return round[msg.sender];
    }
    
    // round마다 사용자의 bet 금액 저장. index 0부터 저장되므로 quizId - 1
    function betToPlay(uint quizId) public payable quizExists(quizId) validBetAmount(quizId){
        bets[quizId-1][msg.sender] += msg.value;
    }

    // quizId에 해당하는 answer와 ans가 같은지 확인하는 함수.
    // 같다면 round +1, quizComplete를 true로 초기화. 그 외는 bet 금액 vault_balance로 이동
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

    // 사용자마다 완료한 quiz에 해당하는 bet 금액 2배를 지급
    function claim() public {
        uint256 reward = 0;
        uint256 betsLength = bets.length;
        for (uint i = 0;i < betsLength;i++) {
            if (quizComplete[msg.sender][i+1]) {
                reward += bets[i][msg.sender];
                quizComplete[msg.sender][i+1] = false; // 이후 claim에서 중복 지급을 예방
            }
        }

        require(reward * 2 <= vault_balance, "Vault balance is not enough...");
        
        vault_balance -= reward * 2;
        payable(msg.sender).transfer(reward * 2);
    }

    // 초기 ether receive
    receive() external payable {
        vault_balance += msg.value;
    }

}
