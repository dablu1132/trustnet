// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Trustnet
 * @dev A decentralized trust and reputation management system
 * @author Trustnet Team
 */
contract Trustnet {
    
    // Struct to represent a user's trust profile
    struct TrustProfile {
        uint256 totalEndorsements;
        uint256 totalRatings;
        uint256 averageRating; // Scaled by 100 (e.g., 450 = 4.5 stars)
        uint256 totalRatingSum; // Sum of all ratings for accurate average calculation
        bool isActive;
        mapping(address => bool) hasEndorsed;
        mapping(address => uint256) ratings;
    }
    
    // Events
    event UserRegistered(address indexed user, uint256 timestamp);
    event EndorsementGiven(address indexed endorser, address indexed endorsed, uint256 timestamp);
    event RatingSubmitted(address indexed rater, address indexed rated, uint256 rating, uint256 timestamp);
    
    // State variables
    mapping(address => TrustProfile) public trustProfiles;
    mapping(address => bool) public registeredUsers;
    uint256 public totalUsers;
    
    // Modifiers
    modifier onlyRegisteredUser() {
        require(registeredUsers[msg.sender], "User must be registered");
        _;
    }
    
    modifier onlyActiveUser(address user) {
        require(trustProfiles[user].isActive, "User profile is not active");
        _;
    }
    
    /**
     * @dev Register a new user in the Trustnet system
     */
    function registerUser() external {
        require(!registeredUsers[msg.sender], "User already registered");
        
        registeredUsers[msg.sender] = true;
        trustProfiles[msg.sender].isActive = true;
        trustProfiles[msg.sender].averageRating = 0;
        trustProfiles[msg.sender].totalRatingSum = 0;
        totalUsers++;
        
        emit UserRegistered(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Endorse another user to build trust relationship
     * @param userToEndorse Address of the user to endorse
     */
    function endorseUser(address userToEndorse) external onlyRegisteredUser onlyActiveUser(userToEndorse) {
        require(userToEndorse != msg.sender, "Cannot endorse yourself");
        require(!trustProfiles[userToEndorse].hasEndorsed[msg.sender], "Already endorsed this user");
        require(registeredUsers[userToEndorse], "User to endorse must be registered");
        
        trustProfiles[userToEndorse].hasEndorsed[msg.sender] = true;
        trustProfiles[userToEndorse].totalEndorsements++;
        
        emit EndorsementGiven(msg.sender, userToEndorse, block.timestamp);
    }
    
    /**
     * @dev Submit a rating for another user (1-5 scale, scaled by 100)
     * @param userToRate Address of the user to rate
     * @param rating Rating value (100-500, representing 1.0-5.0 stars)
     */
    function rateUser(address userToRate, uint256 rating) external onlyRegisteredUser onlyActiveUser(userToRate) {
        require(userToRate != msg.sender, "Cannot rate yourself");
        require(rating >= 100 && rating <= 500, "Rating must be between 1.0 and 5.0 (100-500)");
        require(registeredUsers[userToRate], "User to rate must be registered");
        
        TrustProfile storage profile = trustProfiles[userToRate];
        uint256 previousRating = profile.ratings[msg.sender];
        
        // If user hasn't been rated by this address before, increment total ratings
        if (previousRating == 0) {
            profile.totalRatings++;
            profile.totalRatingSum += rating;
        } else {
            // Update existing rating - subtract old rating and add new one
            profile.totalRatingSum = profile.totalRatingSum - previousRating + rating;
        }
        
        profile.ratings[msg.sender] = rating;
        
        // Recalculate average rating
        if (profile.totalRatings > 0) {
            profile.averageRating = profile.totalRatingSum / profile.totalRatings;
        }
        
        emit RatingSubmitted(msg.sender, userToRate, rating, block.timestamp);
    }
    
    /**
     * @dev Get trust metrics for a user
     * @param user Address of the user to query
     * @return endorsements Total number of endorsements
     * @return ratings Total number of ratings received
     * @return avgRating Average rating (scaled by 100)
     * @return isActive Whether the user profile is active
     */
    function getTrustMetrics(address user) external view returns (
        uint256 endorsements,
        uint256 ratings,
        uint256 avgRating,
        bool isActive
    ) {
        TrustProfile storage profile = trustProfiles[user];
        return (
            profile.totalEndorsements,
            profile.totalRatings,
            profile.averageRating,
            profile.isActive
        );
    }
    
    /**
     * @dev Check if a user has been endorsed by a specific endorser
     * @param user Address of the user
     * @param endorser Address of the potential endorser
     * @return Whether the endorsement exists
     */
    function hasBeenEndorsedBy(address user, address endorser) external view returns (bool) {
        return trustProfiles[user].hasEndorsed[endorser];
    }
    
    /**
     * @dev Get the rating given by a specific rater to a user
     * @param user Address of the rated user
     * @param rater Address of the rater
     * @return The rating value (0 if no rating given)
     */
    function getRatingFrom(address user, address rater) external view returns (uint256) {
        return trustProfiles[user].ratings[rater];
    }
}
