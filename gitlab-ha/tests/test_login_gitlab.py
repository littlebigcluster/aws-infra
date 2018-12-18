import pytest
from fixtures import user
from pytest_bdd import scenario, given, when, then
from splinter import Browser


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


@when('I log in to Gitlab at <url_login>')
def login(url_login, browser, user):
    browser.visit(url_login)
    browser.find_link_by_text('Standard').first.click()
    browser.find_by_id('user_login').fill(user.login)
    browser.find_by_id('user_password').fill(user.password)
    browser.find_by_xpath("//div[@class='submit-container move-submit-down']/input[@name='commit']").first.click()

@then('I am connected to <url>')
def im_connected(url, browser):
    assert browser.url == url

