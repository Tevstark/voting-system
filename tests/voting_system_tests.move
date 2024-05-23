#[test]
module voting_system::voting_system_tests {
    use sui::test_scenario;
    use voting_system::voting_system::{AdminCap, Proposal};
    
    fun test_create_proposal() {
        let mut ctx = test_scenario::new();
        let scenario = test_scenario::begin(&mut ctx);
        {
            voting_system::create_proposal(
                b"Test Proposal",
                b"Test Description",
                1000000000, // start_time (in the past)
                3000000000, // end_time (in the future)
                &mut ctx,
            );
            let proposal = test_scenario::take_shared<Proposal>(&mut scenario);
            assert!(proposal.title == b"Test Proposal", 0);
            assert!(proposal.description == b"Test Description", 0);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_vote() {
        let mut ctx = test_scenario::new();
        let scenario = test_scenario::begin(&mut ctx);
        {
            voting_system::create_proposal(
                b"Test Proposal",
                b"Test Description",
                1000000000, // start_time (in the past)
                3000000000, // end_time (in the future)
                &mut ctx,
            );
            let mut proposal = test_scenario::take_shared<Proposal>(&mut scenario);
            voting_system::vote(&mut proposal, &test_scenario::ctx(&mut scenario).clock, &mut ctx);
            assert!(proposal.total_votes == 1, 0);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_end_voting() {
        let mut ctx = test_scenario::new();
        let scenario = test_scenario::begin(&mut ctx);
        {
            voting_system::create_proposal(
                b"Test Proposal",
                b"Test Description",
                1000000000, // start_time (in the past)
                3000000000, // end_time (in the future)
                &mut ctx,
            );
            let mut proposal = test_scenario::take_shared<Proposal>(&mut scenario);
            voting_system::end_voting(&mut proposal, &mut ctx);
            assert!(proposal.is_voting_ended == true, 0);
        };
        test_scenario::end(scenario);
    }