#!/usr/bin/python3

import pytest
@pytest.fixture(scope="module")
def product(Product, accounts):
    return Product.deploy()