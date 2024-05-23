#[allow(lint(self_transfer))]
module voting_system::voting_system {
    use std::option::{Option, none, some};
    use sui::clock::{Self, Clock};
    use sui::object;
    use sui::tx_context::TxContext;
    use sui::transfer;

    // Error Constants
    const EAlreadyVoted: u64 = 1;
    const EVotingPeriodEnded: u64 = 2;
    const EVotingPeriodNotStarted: u64 = 3;

    // Structs
    public struct AdminCap has key, store {
        id: UID
    }

    public struct Vote has key, store {
        id: UID,
        voter: ID,
        proposal_id: ID,
        voted_at: u64
    }

    public struct Proposal has key, store {
        id: UID,
        title: vector<u8>,
        description: vector<u8>,
        creator: address,
        start_time: u64,
        end_time: Option<u64>,
        total_votes: u64,
        votes: vector<ID>
    }

    // Functions
    fun init(ctx: &mut TxContext) {
        let admin = AdminCap { id: object::new(ctx) };
        transfer::transfer(admin, tx_context::sender(ctx));
    }

    public entry fun create_proposal(
        title: vector<u8>,
        description: vector<u8>,
        start_time: u64,
        end_time: u64,
        ctx: &mut TxContext
    ) {
        let proposal_uid = object::new(ctx);
        let _proposal_id = object::uid_to_inner(&proposal_uid);
        let proposal = Proposal {
            id: proposal_uid,
            title,
            description,
            creator: tx_context::sender(ctx),
            start_time,
            end_time: some(end_time),
            total_votes: 0,
            votes: vector::empty<ID>()
        };
        transfer::share_object(proposal);
    }

    public entry fun vote(proposal: &mut Proposal, clock: &Clock, ctx: &mut TxContext) {
        let current_time = sui::clock::timestamp_ms(clock);
        assert!(current_time >= proposal.start_time, EVotingPeriodNotStarted);
        let end_time = proposal.end_time.borrow();
        assert!(current_time <= *end_time, EVotingPeriodEnded);
        let voter_address = tx_context::sender(ctx);
        let voter_id = object::new(ctx);
        assert!(!vector::contains<ID>(&proposal.votes, &object::uid_to_inner(&voter_id)), EAlreadyVoted);
        let vote_uid = object::new(ctx);
        let vote_id = object::uid_to_inner(&vote_uid);
        let vote = Vote {
            id: vote_uid,
            voter: object::uid_to_inner(&voter_id),
            proposal_id: object::uid_to_inner(&proposal.id),
            voted_at: current_time
        };
        vector::push_back(&mut proposal.votes, vote_id);
        proposal.total_votes = proposal.total_votes + 1;
        transfer::share_object(vote);
        object::delete(voter_id);
    }

    public entry fun end_voting(_: &AdminCap, proposal: &mut Proposal, clock: &Clock) {
        let end_time = proposal.end_time.borrow();
        assert!(*end_time <= clock::timestamp_ms(clock), EVotingPeriodEnded);
        proposal.end_time = none();
    }

    public fun get_voting_results(proposal: &Proposal): (vector<u8>, vector<u8>, u64, u64) {
        (
            proposal.title,
            proposal.description,
            proposal.total_votes,
            proposal.votes.length(),
        )
    }
}