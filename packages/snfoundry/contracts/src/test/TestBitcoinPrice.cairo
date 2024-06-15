use contracts::cryptos::BitcoinPrice::{IBitcoinPriceDispatcher, IBitcoinPriceDispatcherTrait};
use openzeppelin::tests::utils::constants::OWNER;
use openzeppelin::utils::serde::SerializedAppend;
use snforge_std::{declare, ContractClassTrait};
use starknet::ContractAddress;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap();
    let mut calldata = array![];
    calldata.append_serde(252542_u64);
    calldata.append_serde(252542_u64);
    calldata.append_serde(252542_u256);
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}

#[test]
fn test_deployment_values() {
    let contract_address = deploy_contract("BitcoinPrice");

    let dispatcher = IBitcoinPriceDispatcher { contract_address };

    let caller_address = dispatcher.vote_yes(1);
    println!("Caller address {:?}", caller_address);
    
}
