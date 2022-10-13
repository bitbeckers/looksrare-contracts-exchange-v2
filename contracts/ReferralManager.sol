// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// LooksRare unopinionated libraries
import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";

// Interfaces
import {IReferralManager} from "./interfaces/IReferralManager.sol";

/**
 * @title ReferralManager
 * @notice This contract handles the list of referrers for the LooksRare protocol.
 * @author LooksRare protocol team (👀,💎)
 */
contract ReferralManager is IReferralManager, OwnableTwoSteps {
    // Whether the referral program is active
    bool public isReferralProgramActive;

    // Address of the referral controller
    address public referralController;

    // Tracks referrer rates
    mapping(address => uint16) public referrerRates;

    /**
     * @notice Update referrer rate
     * @param referrer Referrer address
     * @param rate Rate percentage to collect (e.g., 100 = 1%) per referred trade
     */
    function updateReferrerRate(address referrer, uint16 rate) external {
        if (msg.sender != referralController) revert NotReferralController();
        if (rate > 10000) revert PercentageTooHigh();

        referrerRates[referrer] = rate;

        emit NewReferrerRate(referrer, rate);
    }

    /**
     * @notice Update status for referral program
     * @param isActive whether the referral program is active
     */
    function updateReferralProgramStatus(bool isActive) external onlyOwner {
        isReferralProgramActive = isActive;
        emit NewReferralProgramStatus(isActive);
    }

    /**
     * @notice Update referral controller
     * @param newReferralController address of new referral controller contract
     */
    function updateReferralController(address newReferralController) external onlyOwner {
        referralController = newReferralController;
        emit NewReferralController(newReferralController);
    }
}
