// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title DecentralizedExamSystem
 * @dev Simple smart contract for decentralized exams
 */
contract DecentralizedExamSystem {
    address public owner;
    
    struct Exam {
        string contentHash;  // IPFS hash of exam content
        uint256 deadline;    // Submission deadline
        bool active;         // Exam status
    }
    
    struct Submission {
        string answerHash;   // IPFS hash of answers
        uint256 timestamp;   // Submission time
        uint256 grade;       // Score (0-100)
        bool isGraded;       // Grading status
    }
    
    // examId => Exam
    mapping(bytes32 => Exam) public exams;
    
    // examId => student => Submission
    mapping(bytes32 => mapping(address => Submission)) public submissions;
    
    // Events
    event ExamCreated(bytes32 indexed examId, string contentHash, uint256 deadline);
    event AnswerSubmitted(bytes32 indexed examId, address indexed student);
    event ExamGraded(bytes32 indexed examId, address indexed student, uint256 grade);
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Create a new exam
     * @param examId Unique exam identifier
     * @param contentHash IPFS hash of exam content
     * @param durationHours Duration in hours
     */
    function createExam(
        bytes32 examId, 
        string calldata contentHash, 
        uint256 durationHours
    ) external {
        require(msg.sender == owner, "Not authorized");
        require(exams[examId].deadline == 0, "Exam already exists");
        require(bytes(contentHash).length > 0, "Invalid content hash");
        
        exams[examId] = Exam({
            contentHash: contentHash,
            deadline: block.timestamp + (durationHours * 1 hours),
            active: true
        });
        
        emit ExamCreated(examId, contentHash, exams[examId].deadline);
    }
    
    /**
     * @dev Submit exam answers
     * @param examId Exam identifier
     * @param answerHash IPFS hash of answers
     */
    function submitExam(
        bytes32 examId, 
        string calldata answerHash
    ) external {
        Exam storage exam = exams[examId];
        
        require(exam.deadline > 0, "Exam doesn't exist");
        require(exam.active, "Exam is not active");
        require(block.timestamp <= exam.deadline, "Deadline passed");
        require(bytes(submissions[examId][msg.sender].answerHash).length == 0, "Already submitted");
        require(bytes(answerHash).length > 0, "Invalid answer hash");
        
        submissions[examId][msg.sender] = Submission({
            answerHash: answerHash,
            timestamp: block.timestamp,
            grade: 0,
            isGraded: false
        });
        
        emit AnswerSubmitted(examId, msg.sender);
    }
    
    /**
     * @dev Grade a submission
     * @param examId Exam identifier
     * @param student Student address
     * @param grade Score (0-100)
     */
    function gradeExam(
        bytes32 examId, 
        address student, 
        uint256 grade
    ) external {
        require(msg.sender == owner, "Not authorized");
        require(grade <= 100, "Grade must be 0-100");
        require(bytes(submissions[examId][student].answerHash).length > 0, "No submission found");
        require(!submissions[examId][student].isGraded, "Already graded");
        
        submissions[examId][student].grade = grade;
        submissions[examId][student].isGraded = true;
        
        emit ExamGraded(examId, student, grade);
    }
}
