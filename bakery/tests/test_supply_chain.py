
from brownie import supplyChain, accounts

def test_owner():
    account = accounts[0]
    supply_chain = supplyChain.deploy({'from': account})
    tx = supply_chain.get_owner({'from': account})
    tx.wait(1)
    assert supply_chain.owner() == account.address