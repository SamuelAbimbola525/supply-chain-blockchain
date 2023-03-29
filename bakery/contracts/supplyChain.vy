# SupplyChain.vy

# Contract owner
owner: public(address)

# Define participant types
enum ParticipantType:
    MANUFACTURER
    DISTRIBUTOR
    RETAILER
    CUSTOMER


# Define participants structure
struct Participant:
    participantId: uint256
    participantType: ParticipantType
    name: String[100]
    wallet: address

# Participant counter for unique IDs
participantCounter: uint256

# Store participants by their IDs
participants: HashMap[uint256, Participant]

# Store registered participant IDs
registeredParticipantIds: HashMap[uint256, bool]


# Define item structure
struct Item:
    itemId: uint256
    name: String[100]
    description: String[256]
    price: uint256
    manufacturerId: uint256
    ownerId: uint256

# Item counter for unique IDs
itemCounter: uint256

# Store items by their IDs
items: HashMap[uint256, Item]


# Define ownership transfer structure
struct OwnershipTransfer:
    itemId: uint256
    fromId: uint256
    toId: uint256
    transferTime: uint256

# Ownership transfer counter for unique IDs
transferCounter: uint256

# Store ownership transfers by their IDs
transfers: HashMap[uint256, OwnershipTransfer]

# Event to notify when ownership is transferred
event OwnershipTransferred:
    itemId: uint256
    fromId: uint256
    toId: uint256
    transferTime: uint256


@external
def __init__():
    self.owner = msg.sender

@external
def get_owner() -> address:
    return self.owner


# Event to notify when a participant is registered
event  ParticipantRegistered:
    participantId: indexed(uint256)
    participantType: ParticipantType 
    name: String[100]
    wallet: indexed(address)

# Event to notify when an item is added
event ItemAdded:
    itemId: indexed(uint256)
    name: String[100]
    description: String[256]
    price: uint256
    manufacturerId: indexed(uint256)
    ownerId: indexed(uint256)


# Register a new participant
@external
def register_participant(_participantType: ParticipantType, _name: String[100], _wallet: address) -> uint256:
    self.participantCounter += 1
    newParticipant: Participant = Participant({participantId: self.participantCounter, participantType: _participantType, name: _name, wallet: _wallet})
    self.participants[newParticipant.participantId] = newParticipant
    self.registeredParticipantIds[self.participantCounter] = True

    log ParticipantRegistered(self.participantCounter, _participantType, _name, _wallet)
    return self.participantCounter

# Add a new item
@external
def add_item(_name: String[100], _description: String[256], _price: uint256, _manufacturerId: uint256) -> uint256:
    # Ensure the manufacturer is registered
    assert self.is_registered(_manufacturerId), "Manufacturer is not registered"

    manufacturer: Participant = self.participants[_manufacturerId]
    assert manufacturer.participantType == ParticipantType.MANUFACTURER, "Manufacturer is not a MANUFACTURER"
    self.itemCounter += 1
    newItem: Item = Item({itemId: self.itemCounter, name: _name, description: _description, price: _price, manufacturerId: _manufacturerId, ownerId: _manufacturerId})
    self.items[self.itemCounter] = newItem
    log ItemAdded(self.itemCounter, _name, _description, _price, _manufacturerId, _manufacturerId)
    return self.itemCounter


# Transfer item ownership
@internal
def transfer_ownership(_itemId: uint256, _newOwnerId: uint256):
    # Ensure the item exists
    assert self.is_registered(self.items[_itemId].ownerId)
    
    # Ensure the current owner is the message sender
    assert msg.sender == self.participants[self.items[_itemId].ownerId].wallet
    
    # Ensure the new owner is registered
    assert self.is_registered(_newOwnerId)
    
    # Update the item's owner
    self.items[_itemId].ownerId = _newOwnerId
    
    # Record the ownership transfer
    self.transferCounter += 1
    newTransfer: OwnershipTransfer = OwnershipTransfer({itemId: _itemId, fromId: self.items[_itemId].ownerId, toId: _newOwnerId, transferTime: block.timestamp})
    self.transfers[self.transferCounter] = newTransfer
    
    # Emit the OwnershipTransferred event
    log OwnershipTransferred(_itemId, self.items[_itemId].ownerId, _newOwnerId, block.timestamp)


# Purchase an item
@external
@payable
def purchase_item(_itemId: uint256, _customerId: uint256):
    # Ensure the item exists
    itemOwner: Item = self.items[_itemId]
    assert self.is_registered(itemOwner.ownerId), "Owner is not registered"
    
    # Ensure the customer is registered and is of type CUSTOMER
    assert self.is_registered(_customerId)

    customer: Participant = self.participants[_customerId]
    assert customer.participantType == ParticipantType.CUSTOMER, "Customer is not a CUSTOMER"
    
    # Ensure the owner of the item is a retailer
    retailer: Participant = self.participants[itemOwner.ownerId]
    assert retailer.participantType == ParticipantType.RETAILER
    
    # Ensure the correct amount of Ether is sent for the purchase
    assert msg.value == self.items[_itemId].price
    
    # Transfer the amount to the retailer's wallet
    send(self.participants[self.items[_itemId].ownerId].wallet, msg.value)
    
    # Transfer ownership of the item to the customer
    self.transfer_ownership(_itemId, _customerId)


# Check if a participant is registered
@internal
def is_registered(_participantId: uint256) -> bool:
    return self.registeredParticipantIds[_participantId]