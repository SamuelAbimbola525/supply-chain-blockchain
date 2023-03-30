from brownie import supplyChain, config, accounts
def deploy_wallet():
    account = accounts.add(config["wallets"]["from_key"])
    contract = supplyChain.deploy({"from":account}, publish_source=True)
    print(f"Contract deployed to {contract.address}")
def main():
    deploy_wallet()