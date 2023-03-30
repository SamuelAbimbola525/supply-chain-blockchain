
from brownie import supplyChain, accounts


def test_owner():
    account = accounts[0]
    supply_chain = supplyChain.deploy({'from': account})
    tx = supply_chain.get_owner({'from': account})
    tx.wait(1)
    assert supply_chain.owner() == account.address


def test_register_participants():
   # Deploy the SupplyChain contract using the first account
    account = accounts[0]
    supply_chain = supplyChain.deploy({'from': account})

    # Register a manufacturer
    manufacturer_tx = supply_chain.register_participant(
        1, "Manufacturer", accounts[1], {'from': account})
    manufacturer_id = manufacturer_tx.events['ParticipantRegistered']['participantId']
    manufacturer = supply_chain.get_participant(manufacturer_id)

    # Check if the manufacturer was registered correctly
    assert manufacturer[0] == manufacturer_id
    assert manufacturer[1] == 1
    assert manufacturer[2] == "Manufacturer"
    assert manufacturer[3] == accounts[1]

    # Register a distributor
    distributor_tx = supply_chain.register_participant(
        2, "Distributor", accounts[2], {'from': account})
    distributor_id = distributor_tx.events['ParticipantRegistered']['participantId']
    distributor = supply_chain.get_participant(distributor_id)

    # Check if the distributor was registered correctly
    assert distributor[0] == distributor_id
    assert distributor[1] == 2
    assert distributor[2] == "Distributor"
    assert distributor[3] == accounts[2]

    # Register a retailer
    retailer_tx = supply_chain.register_participant(
        3, "Retailer", accounts[3], {'from': account})
    retailer_id = retailer_tx.events['ParticipantRegistered']['participantId']
    retailer = supply_chain.get_participant(retailer_id)

    # Check if the retailer was registered correctly
    assert retailer[0] == retailer_id
    assert retailer[1] == 3
    assert retailer[2] == "Retailer"
    assert retailer[3] == accounts[3]

    # Register a customer
    customer_tx = supply_chain.register_participant(
        4, "Customer", accounts[4], {'from': account})
    customer_id = customer_tx.events['ParticipantRegistered']['participantId']
    customer = supply_chain.get_participant(customer_id)

    # Check if the customer was registered correctly
    assert customer[0] == customer_id
    assert customer[1] == 4
    assert customer[2] == "Customer"
    assert customer[3] == accounts[4]


def test_add_item():
    # Deploy the SupplyChain contract using the first account
    account = accounts[0]
    supply_chain = supplyChain.deploy({'from': account})

    # Register a manufacturer
    manufacturer_tx = supply_chain.register_participant(
        1, "Manufacturer", accounts[1], {'from': account})
    manufacturer_id = manufacturer_tx.events['ParticipantRegistered']['participantId']

    # Add an item to the supply chain by the manufacturer
    item_name = "Item 1"
    item_description = "This is a test item"
    item_price = 100
    add_item_tx = supply_chain.add_item(
        item_name, item_description, item_price, manufacturer_id, {'from': accounts[1]})
    item_id = add_item_tx.events['ItemAdded']['itemId']
    item_data = supply_chain.get_item(item_id)

    # Check if the item was added correctly
    assert item_data[0] == item_id
    assert item_data[1] == item_name
    assert item_data[2] == item_description
    assert item_data[3] == item_price
    assert item_data[4] == manufacturer_id
    assert item_data[5] == manufacturer_id


def test_external_transfer_ownership():
    # Deploy the SupplyChain contract using the first account
    account = accounts[0]
    supply_chain = supplyChain.deploy({'from': account})

    # Register a manufacturer
    manufacturer_tx = supply_chain.register_participant(
        1, "Manufacturer", accounts[1], {'from': account})
    manufacturer_id = manufacturer_tx.events['ParticipantRegistered']['participantId']
    # Register a retailer
    retailer_tx = supply_chain.register_participant(
        3, "Retailer", accounts[3], {'from': account})
    retailer_id = retailer_tx.events['ParticipantRegistered']['participantId']

    # Add an item to the supply chain by the manufacturer
    item_name = "Item 1"
    item_description = "This is a test item"
    item_price = 100
    add_item_tx = supply_chain.add_item(
        item_name, item_description, item_price, manufacturer_id, {'from': accounts[1]})
    item_id = add_item_tx.events['ItemAdded']['itemId']

    # Transfer ownership to the retailer
    transfer_tx = supply_chain.external_transfer_ownership(
        item_id, retailer_id, {'from': accounts[1]})
    transfer_event = transfer_tx.events['OwnershipTransferred']

    # Check if the ownership was transferred correctly
    item_data = supply_chain.get_item(item_id)
    assert item_data[5] == retailer_id
    assert transfer_event['itemId'] == item_id
    assert transfer_event['fromId'] == manufacturer_id
    assert transfer_event['toId'] == retailer_id


def test_purchase_item():
    # Deploy the SupplyChain contract using the first account
    account = accounts[0]
    supply_chain = supplyChain.deploy({'from': account})

    # Register a manufacturer
    manufacturer_tx = supply_chain.register_participant(
        1, "Manufacturer", accounts[1], {'from': account})
    manufacturer_id = manufacturer_tx.events['ParticipantRegistered']['participantId']

    # Add an item to the supply chain by the manufacturer
    item_name = "Item 1"
    item_description = "This is a test item"
    item_price = 100
    add_item_tx = supply_chain.add_item(
        item_name, item_description, item_price, manufacturer_id, {'from': accounts[1]})
    item_id = add_item_tx.events['ItemAdded']['itemId']

    # Register a retailer
    retailer_tx = supply_chain.register_participant(
        3, "Retailer", accounts[3], {'from': account})
    retailer_id = retailer_tx.events['ParticipantRegistered']['participantId']

    # Transfer ownership of the item to the retailer
    supply_chain.external_transfer_ownership(
        item_id, retailer_id, {'from': accounts[1]})

    # Register a customer
    customer_tx = supply_chain.register_participant(
        4, "Customer", accounts[4], {'from': account})
    customer_id = customer_tx.events['ParticipantRegistered']['participantId']
    # Purchase the item by the customer
    purchase_tx = supply_chain.purchase_item(item_id, customer_id, {'from': accounts[4], 'value': item_price})

    # Check if the item was transferred to the customer
    item_data = supply_chain.get_item(item_id)
    assert item_data[5] == customer_id

    # Check if the ownership transfer was recorded correctly
    transfer_data = supply_chain.transfers(1)
    assert transfer_data.itemId == item_id
    assert transfer_data.fromId == retailer_id
    assert transfer_data.toId == customer_id
    assert transfer_data.transferTime > 0

    # Check if the retailer received the payment
    assert accounts[3].balance() == item_price
