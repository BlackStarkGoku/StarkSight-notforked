use starknet::ContractAddress;

#[starknet::interface]
pub trait IBitcoinPrice<TContractState> {
    fn vote_yes(ref self: TContractState, amount_eth: u256);
}

#[starknet::contract]
pub mod BitcoinPrice {
    use super::IBitcoinPrice;
    use starknet::ContractAddress;
    use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};
    use starknet::{get_caller_address, get_contract_address, get_block_timestamp};
    const ETH_CONTRACT_ADDRESS: felt252 =
        0x49D36570D4E46F48E99674BD3FCC84644DDD6B96F7C741B1562B82F9E004DC7;

    #[storage]
    struct Storage {
        eth_token: IERC20CamelDispatcher,
        total_bets: u64,
        balance: u256,
        current_bet: BetInfos,
        bets_history: LegacyMap::<u64, BetInfos>
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct BetInfos {
        id: u64,
        total_amount: u256,
        total_amount_yes: u256,
        total_amount_no: u256,
        begin_date: u64,
        end_date: u64,
        token_price_start: u256,
        reference_token_price: u256,
        vote_date_limit: u64,

    }


    #[constructor]
    fn constructor(ref self: ContractState, end_date: u64, vote_date_limit: u64, reference_token_price: u256) {
        let eth_contract_address = ETH_CONTRACT_ADDRESS.try_into().unwrap();
        self.eth_token.write(IERC20CamelDispatcher { contract_address: eth_contract_address });
        self.balance.write(0);
        self.total_bets.write(1); // First bet when contract is created

        let current_bet = BetInfos {
            id: 0,
            total_amount: 0,
            total_amount_yes: 0,
            total_amount_no: 0,
            begin_date: get_current_timestamp(),
            end_date: end_date,
            token_price_start: 0, // TODO: Fetch from pragma
            reference_token_price: reference_token_price,
            vote_date_limit: vote_date_limit,
        };
        self.current_bet.write(current_bet);
        self.bets_history.write(0, current_bet); // TODO: Remove this, make It when bet is over
    }

 
    fn get_current_timestamp() -> u64 {
        let timestamp = get_block_timestamp();
        timestamp
    }
    
    fn assert_bet_period_validity(self: @ContractState) {
        let current_timestamp = get_current_timestamp();
        let start_vote_bet_timestamp = self.current_bet.read().begin_date;
        let end_vote_bet_timestamp = self.current_bet.read().vote_date_limit;
        assert!(current_timestamp >= start_vote_bet_timestamp, "Vote has not started yet");
        assert!(current_timestamp <= end_vote_bet_timestamp, "Vote is over");
    }


    #[abi(embed_v0)]
    impl BitcoinImpl of IBitcoinPrice<ContractState> {
        fn vote_yes(ref self: ContractState, amount_eth: u256) {
            assert_bet_period_validity(@self);
            let caller_address = get_caller_address();
            if amount_eth > 0 {
                // call approve on UI
                self
                    .eth_token
                    .read()
                    .transferFrom(caller_address, get_contract_address(), amount_eth);

                    let mut current_bet : BetInfos = self.current_bet.read();
                    current_bet.total_amount += amount_eth;
                    current_bet.total_amount_yes += amount_eth;
                    // TODO: Add user in stockage
            }
        }
    }
}