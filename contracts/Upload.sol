// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Upload {

    uint256 private totalOperations;
    uint256 private startTime;
    uint256 private timeWindow = 1 hours;

    struct Access {
        address user;
        bool access; // true or false
    }

    event DataIntegrityVerified(address indexed user, bytes32 calculatedRoot, bytes32 storedRoot);
    event MerkleTreeHeightCalculated(address indexed user, uint256 height);

    constructor() {
        startTime = block.timestamp;
    }

    mapping(address => string[]) value;
    mapping(address => mapping(address => bool)) ownership;
    mapping(address => Access[]) accessList;
    mapping(address => mapping(address => bool)) previousData;
    mapping(address => bytes32) merkleRoots;

    uint256 constant MAX_CHILDREN = 2; // Maximum children per node
    uint256 constant MAX_HEIGHT = 256; // Maximum tree height



    // INCREMENT TOTAL OPERATIONS COUNT
    function incrementTotalOperations() internal {
        totalOperations++;
    }

    // CALCULATE THROUGHPUT
    function calculateThroughput() internal view returns (uint256) {
        uint256 elapsedTime = block.timestamp - startTime;
        return (totalOperations * 1 ether) / elapsedTime; // Throughput in operations per second (OPS)
    }

    // ADD DATA TO MERKLE TREE
    function addToMerkleTree(address _user, string memory url) internal {
        value[_user].push(url);
        // Recalculate Merkle root when new data is added
        merkleRoots[_user] = calculateMerkleRoot(_user);
    }

    // MERKLE ROOT OF USER'S DATA
    function calculateMerkleRoot(address _user) internal view returns (bytes32) {
        string[] memory data = value[_user];
        bytes32[] memory leaves = new bytes32[](data.length);

        for (uint i = 0; i < data.length; i++) {
            leaves[i] = keccak256(abi.encodePacked(data[i]));
        }

        return createMerkleTree(leaves);
    }

    // CREATE MERKLE TREE FROM LEAF NODES
    function createMerkleTree(bytes32[] memory leaves) internal pure returns (bytes32) {
        uint n = leaves.length;
        if (n == 0) {
            return 0x0;
        }

        while (n > 1) {
            for (uint i = 0; i < n; i += 2) {
                if (i + 1 < n) {
                    leaves[(i / 2)] = keccak256(abi.encodePacked(leaves[i], leaves[i + 1]));
                } else {
                    leaves[(i / 2)] = leaves[i];
                }
            }
            n = (n + 1) / 2;
        }

        return leaves[0];
    }

    // MERKLE TREE HEIGHT
    function calculateMerkleTreeHeight(address _user) external view returns (uint256) {
        uint256 height = 0;
        uint256 leafCount = value[_user].length;

        while (leafCount > 1) {
            leafCount = (leafCount + 1) / 2;
            height++;
        }
        return height;
    }

    // ADD DATA AND UPDATE MERKLE TREE
    function add(address _user, string memory url) external {
        addToMerkleTree(_user, url);
        incrementTotalOperations();
    }

    // ALLOW OWNERSHIP
    function allow(address user) external {//def
        ownership[msg.sender][user] = true; 
        if (previousData[msg.sender][user]) {
            for (uint i = 0; i < accessList[msg.sender].length; i++) {
                if (accessList[msg.sender][i].user == user) {
                    accessList[msg.sender][i].access = true; 
                }
            }
        } else {
            accessList[msg.sender].push(Access(user, true));  
            previousData[msg.sender][user] = true;  
        }
    }

    // DISALLOW OWNERSHIP
    function disallow(address user) public {
        ownership[msg.sender][user] = false;
        for (uint i = 0; i < accessList[msg.sender].length; i++) {
            if (accessList[msg.sender][i].user == user) {
                accessList[msg.sender][i].access = false;  
            }
        }
    }

    function display(address _user) external view returns (string[] memory) {
        require(_user == msg.sender || ownership[_user][msg.sender], "You don't have access");
        return value[_user];
    }

    function shareAccess() public view returns (Access[] memory) {
        return accessList[msg.sender];
    }

    // VERIFY DATA INTEGRITY USING MERKLE TREE
    function verifyDataIntegrity(address _user) internal returns (bool) {
        bytes32 currentRoot = calculateMerkleRoot(_user);
        emit DataIntegrityVerified(_user, currentRoot, merkleRoots[_user]);
        return currentRoot == merkleRoots[_user];
    }

    // CALCULATE GAS COST FOR VERIFYING DATA INTEGRITY
    function calculateGasCostForVerification(address _user) external returns (uint256) {
    uint256 gasStart = gasleft(); // Start gas measurement

    // Call verifyDataIntegrity function to measure gas cost
    verifyDataIntegrity(_user);

    uint256 gasEnd = gasleft(); // End gas measurement

    uint256 gasUsed = gasStart - gasEnd; // Calculate gas used
    return gasUsed;
    }

    // NUMBER OF NODES
    function calculateTotalNodes(address _user) internal view returns (uint256) {
    uint256 leafCount = value[_user].length;
    uint256 totalNodes = leafCount; // Start with leaf nodes count

    // Calculate total nodes recursively
    while (leafCount > 1) {
        leafCount = (leafCount + MAX_CHILDREN - 1) / MAX_CHILDREN; // Round up division
        totalNodes += leafCount;
    }

    return totalNodes;
    }

    // STORAGE EFFICIENCY
    function calculateStorageEfficiency(address _user) external view returns (uint256) {
    uint256 leafCount = value[_user].length;
    uint256 totalNodes = calculateTotalNodes(_user);
    
    // Ensure totalNodes is not zero to avoid division by zero
    require(totalNodes > 0, "Total nodes count is zero");

    // Calculate storage efficiency
    return (leafCount * 10000) / totalNodes; // Multiply by 10000 to get percentage with 2 decimal places
    }


    // RETURN CURRENT THROUGHPUT
    function getCurrentThroughput() external view returns (uint256) {
        return calculateThroughput();
    }


}