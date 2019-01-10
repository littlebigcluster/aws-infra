Feature: Gitlab
    A web-based Git-repository manager providing wiki, issue-tracking and CI features

Scenario: Log in to Gitlab with admin user
    Given I am an administrator user with login : <login> and password : <password>
    And Gitlab is available at <url>
    When I log in to Gitlab at <url_login>
    Then I am connected to <url>

Examples:
    | login | password | url | url_login |
    | root | gitlab_root_password | https://gitlab.anybox.cloud/ | https://gitlab.anybox.cloud/users/sign_in |
