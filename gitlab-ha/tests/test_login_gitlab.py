# coding: utf-8
import os
import pytest
import urllib
from fixtures import user
from pytest_bdd import scenario, given, when, then
from splinter import Browser

# on ajoute temporairement les drivers présents dans le dossiers drivers au path 
DRIVERS = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'drivers/')
for directory in os.listdir(DRIVERS):
    os.environ['PATH'] += ":" + os.path.join(DRIVERS, directory)


@scenario('login_gitlab.feature', 'Log in to Gitlab with admin user')
def test_login_gitlab():
    pass


@given("I am an administrator user with login : <login> and password : <password>")
def administrator_user(login, password, user):
    user.login = login
    user.password = password


@given('Gitlab is available at <url>')
def gitlab(url, browser):
    browser.visit(url)
    assert urllib.urlopen(url).getcode() == 200


@when('I log in to Gitlab at <url_login>')
def login(url_login, browser, user):
    browser.visit(url_login)
    browser.find_link_by_text('Standard').first.click()
    browser.find_by_id('user_login').fill(user.login)
    browser.find_by_id('user_password').fill(user.password)
    browser.find_by_xpath(
        "//div[@class='submit-container move-submit-down']/input[@name='commit']"
    ).first.click()


@then('I am connected to <url>')
def im_connected(url, browser):
    assert browser.url == url
    assert browser.is_element_present_by_xpath(
        "//li[@class='nav-item header-user dropdown']/a[@class='header-user-dropdown-toggle']"
    )
    browser.find_by_xpath(
        "//li[@class='nav-item header-user dropdown']/a[@class='header-user-dropdown-toggle']"
    ).first.click()
    assert browser.is_element_present_by_xpath(
        "//li[@class='current-user']/div[@class='user-name bold']"
    )
    assert browser.find_by_xpath(
        "//li[@class='current-user']/div[@class='user-name bold']"
    ).first.text == u'Administrator'
