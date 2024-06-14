#[starknet::interface]
pub trait IBitcoinPrice<TContractState> {}

#[starknet::contract]
pub mod BitcoinPrice {
    use super::IBitcoinPrice;
    use starknet::ContractAddress;
    use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};
    use starknet::get_block_timestamp;

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
        self.total_bets.write(0);
        
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
        self.bets_history.write(0, current_bet);
    }

    fn get_current_timestamp() -> u64 {
        let timestamp = get_block_timestamp();
        timestamp
    }

    #[abi(embed_v0)]
    impl BitcoinImpl of IBitcoinPrice<ContractState> {
    }
}