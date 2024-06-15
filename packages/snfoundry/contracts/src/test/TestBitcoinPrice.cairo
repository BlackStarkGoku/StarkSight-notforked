use core::traits::TryInto;
use contracts::cryptos::BitcoinPrice::{IBitcoinPriceDispatcher, IBitcoinPriceDispatcherTrait};
use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};
use openzeppelin::tests::utils::constants::OWNER;
use openzeppelin::utils::serde::SerializedAppend;
use snforge_std::{declare, ContractClassTrait, prank, CheatTarget, CheatSpan};
use starknet::ContractAddress;

//use debug::PrintTrait;

const ETH_CONTRACT_ADDRESS: felt252 =
        0x49D36570D4E46F48E99674BD3FCC84644DDD6B96F7C741B1562B82F9E004DC7;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap();
    let mut calldata = array![];
    
    let end_vote_bet_timestamp: u64 = 4102444800; // 1er janvier 2100
    let end_bet_timestamp: u64 = 4102444800_u64; // 1 février 2100
    calldata.append_serde(end_vote_bet_timestamp);
    calldata.append_serde(end_bet_timestamp);
    calldata.append_serde(252542_u256);
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}

fn setup() -> IERC20CamelDispatcher {
    //let contract_address = deploy_contract("BitcoinPrice");
    //contract_address.print();
    //let dispatcher = IBitcoinPriceDispatcher { contract_address };


    let eth_contract_address = ETH_CONTRACT_ADDRESS.try_into().unwrap();
    let eth_token = IERC20CamelDispatcher { contract_address: eth_contract_address };
    eth_token
}

#[test]
#[fork("TEST")]
fn test_check_vote_availibility_period() {
    let contract_address = deploy_contract("BitcoinPrice");
    let eth_token = setup();
    prank(CheatTarget::One(contract_address), 0x0213c67ed78bc280887234fe5ed5e77272465317978ae86c25a71531d9332a2d.try_into().unwrap(), CheatSpan::TargetCalls(1));
    
    let dispatcher = IBitcoinPriceDispatcher { contract_address };


    assert!(eth_token.balanceOf(dispatcher.contract_address) == 0, "Balance is suposed to be 0");
    prank(CheatTarget::One(eth_token.contract_address), 0x0213c67ed78bc280887234fe5ed5e77272465317978ae86c25a71531d9332a2d.try_into().unwrap(), CheatSpan::TargetCalls(1));
    eth_token.approve(contract_address, 1);
    dispatcher.vote_yes(1);
    println!("Done transaction");

    assert!(eth_token.balanceOf(dispatcher.contract_address) == 1, "Balance is suposed to be 1");

 
}

//#[test]
//fn test_vote_yes() {
    //let contract_address = deploy_contract("BitcoinPrice");

    //let dispatcher = IBitcoinPriceDispatcher { contract_address };

    //let caller_address = dispatcher.vote_yes(1);
    //println!("Caller address {:?}", caller_address);
//}
