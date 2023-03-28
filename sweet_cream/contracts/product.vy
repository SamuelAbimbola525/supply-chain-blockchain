from vyper.interfaces import ERC20

# Event to be emitted when a new product is created
event NewProduct:
    id: uint256
    name: String[50]
    description: String[255]
    quantity: uint256
    price: uint256
    producer: address

# Event to be emitted when a product is updated
event ProductUpdated:
    id: uint256
    name: String[50]
    description: String[255]
    quantity: uint256
    price: uint256
    producer: address

# Product struct
struct Product:
    id: uint256
    name: String[50]
    description: String[255]
    quantity: uint256
    price: uint256
    producer: address

# Mapping of product IDs to Product structs
products: HashMap[uint256, Product]

# Variable to keep track of the next product ID
next_product_id: uint256

@external
def create_product(name: String[50], description: String[255], quantity: uint256, price: uint256) -> uint256:
    assert len(name) > 0, "Product name cannot be empty."
    assert len(description) > 0, "Product description cannot be empty."
    assert quantity > 0, "Product quantity must be greater than 0."
    assert price > 0, "Product price must be greater than 0."


    product_id: uint256 = self.next_product_id
    self.next_product_id += 1

    new_product: Product = Product({id: product_id, name: name, description: description, quantity: quantity, price: price, producer: msg.sender})
    self.products[product_id] = new_product

    log NewProduct(product_id, name, description, quantity, price, msg.sender)
    return product_id

@external
def update_product(product_id: uint256, name: String[50], description: String[255], quantity: uint256, price: uint256):
    assert msg.sender == self.products[product_id].producer, "Only the producer can update the product."

    if len(name) > 0:
        self.products[product_id].name = name

    if len(description) > 0:
        self.products[product_id].description = description

    if quantity > 0:
        self.products[product_id].quantity = quantity

    if price > 0:
        self.products[product_id].price = price

    log ProductUpdated(product_id, name, description, quantity, price, msg.sender)


@external
def update_product_quantity(product_id: uint256, new_quantity: uint256):
    assert msg.sender == self.products[product_id].producer, "Only the producer can update the quantity."
    if new_quantity > 0:
        self.products[product_id].quantity = new_quantity

@external
def update_product_price(product_id: uint256, new_price: uint256):
    assert msg.sender == self.products[product_id].producer, "Only the producer can update the price."
    if new_price > 0:
        self.products[product_id].price = new_price


#Product and Product Attribute Getters
@view
@external
def get_product(product_id: uint256) -> Product:
    return self.products[product_id]

@view
@external
def get_product_name(product_id: uint256) -> String[50]:
    return self.products[product_id].name

@view
@external
def get_product_price(product_id: uint256) -> uint256:
    return self.products[product_id].price

@view
@external
def get_product_quantity(product_id: uint256) -> uint256:
    return self.products[product_id].quantity


@view
@external
def get_product_owner(product_id: uint256) -> address:
    return self.products[product_id].producer


@view
@external
def get_product_count() -> uint256:
    return self.next_product_id