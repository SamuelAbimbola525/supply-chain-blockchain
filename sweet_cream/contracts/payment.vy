from vyper.interfaces import ERC20

erc20: ERC20

@external
def __init__(_erc20: address):
    self.erc20 = ERC20(_erc20)

@external
def transfer_tokens(to: address, amount: uint256):
    self.erc20.transfer(to, amount)

@external
def purchase_product(product_contract: address, product_id: uint256, quantity: uint256):
    response: Bytes[32] = raw_call(product_contract, concat(method_id("get_product_price(uint256)"), convert(product_id, bytes32)), gas=50000, value=0, max_outsize=32, is_static_call=True)
    product_price: uint256 = convert(response, uint256)
    total_cost: uint256 = product_price * quantity
    assert self.erc20.transferFrom(msg.sender, product_contract, total_cost), "Token transfer failed"