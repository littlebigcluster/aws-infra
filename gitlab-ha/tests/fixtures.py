# coding: utf-8
import pytest


@pytest.fixture
def user():
    return User()


class User(object):

    def __init__(self, login=None, password=None):
        self.login = login
        self.password = password
