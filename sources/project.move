module MyModule::HackathonBountyBoard {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    /// Struct representing a hackathon bounty with milestone-based payouts
    struct Bounty has store, key {
        total_reward: u64,        // Total bounty amount
        milestones_completed: u8, // Number of milestones completed (0-3)
        total_milestones: u8,     // Total milestones (fixed at 3)
        participant: address,     // Address of the participating team
        is_active: bool,          // Whether bounty is still active
    }

    /// Function to create a new hackathon bounty with funding
    public fun create_bounty(
        organizer: &signer, 
        total_reward: u64, 
        participant: address
    ) {
        // Transfer the total reward from organizer to contract
        let reward_coins = coin::withdraw<AptosCoin>(organizer, total_reward);
        coin::deposit<AptosCoin>(signer::address_of(organizer), reward_coins);

        // Create bounty struct
        let bounty = Bounty {
            total_reward,
            milestones_completed: 0,
            total_milestones: 3,
            participant,
            is_active: true,
        };
        
        move_to(organizer, bounty);
    }

    /// Function to complete milestone and release proportional payment
    public fun complete_milestone(
        organizer: &signer, 
        participant_address: address
    ) acquires Bounty {
        let bounty = borrow_global_mut<Bounty>(signer::address_of(organizer));
        
        // Check if bounty is active and milestones remain
        assert!(bounty.is_active, 1);
        assert!(bounty.milestones_completed < bounty.total_milestones, 2);
        assert!(bounty.participant == participant_address, 3);

        // Calculate milestone payout (1/3 of total reward per milestone)
        let milestone_payout = bounty.total_reward / (bounty.total_milestones as u64);
        
        // Transfer milestone payment to participant
        let payment = coin::withdraw<AptosCoin>(organizer, milestone_payout);
        coin::deposit<AptosCoin>(participant_address, payment);

        // Update milestone progress
        bounty.milestones_completed = bounty.milestones_completed + 1;

        // Deactivate bounty if all milestones completed
        if (bounty.milestones_completed == bounty.total_milestones) {
            bounty.is_active = false;
        };
    }
}