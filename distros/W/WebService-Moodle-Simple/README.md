# NAME

WebService::Moodle::Simple - Client API and CLI for Moodle Web Services

# SYNOPSIS

## CLI

    moodlews login        - login with your Moodle password and retrieve token
    moodlews add_user     - Create a Moodle user account
    moodlews get_users    - Get all users
    moodlews enrol        - Enrol user into a course
    moodlews set_password - Update a user account password

## API

    use WebService::Moodle::Simple;

    my $moodle = WebService::Moodle::Simple->new(
      domain   =>  'moodle.example.edu',
      target   =>  'example_webservice'
    );

    my $rh_token = $moodle->login( username => 'admin', password => 'p4ssw0rd');

# DESCRIPTION

WebService::Moodle::Simple is Client API and CLI for Moodle Web Services

\_\_THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE\_\_.

# USAGE

## CLI

Get instructions on CLI usage

    moodlews

## Example - Login and Get Users

    moodlews login -u admin -d moodle.example.edu -p p4ssw0rd -t example_webservice

Retrieve the user list using the token returned from the login command

    moodlews get_users -o becac8d120119eb2a312a385644eb709 -d moodle.example.edu -t example_webservice

## Unit Tests

    prove -rlv t

### Full Unit Tests

    TEST_WSMS_ADMIN_PWD=p4ssw0rd \
    TEST_WSMS_DOMAIN=moodle.example.edu \
    TEST_WSMS_TARGET=example_webservice prove -rlv t

\_\_NOTE: Full unit tests write to Moodle Database - only run them against a test Moodle server\_\_.

## Methods

- _$OBJ_->login(
  username => _str_,
  password => _str_,
)

    Returns { msg => _str_, ok => _bool_, token => _str_ }

- _$OBJ_->set\_password(
  username => _str_,
  password => _str_,
  token    => _str_,
)
- _$OBJ_->add\_user(
  firstname => _str_,
  lastname  => _str_,
  email     => _str_,
  username  => _str_,
  password  => _str_,
  token     => _str_,
)
- _$OBJ_->get\_users(
  token     => _str_,
)
- _$OBJ_->enrol\_student(
  username  => _str_,
  course    => _str_,
  token     => _str_,
)
- _$OBJ_->get\_course\_id(
  short\_cname  => _str_,
  token        => _str_,
)
- _$OBJ_->get\_user(
  token        => _str_,
  username     => _str_,
)
- _$OBJ_->suspend\_user(
  token    => _str_,
  username => _str_,
  suspend  => _bool default TRUE_
)

    If suspend is true/nonzero (which is the default) it kills the user's session
    and suspends their account preventing them from logging in. If suspend is false
    they are given permission to login. NOTE: This will only work if the Moodle
    server has had this patch (or its equivalent) applied:
    https://github.com/fabiomsouto/moodle/compare/MOODLE\_22\_STABLE...MDL-31465-MOODLE\_22\_STABLE

- _$OBJ_->raw\_api(
    method => _moodle webservice method name_,
    token  => _str_,
    params => _hashref of method parameters_
)

    returns Moodle's response.

# AUTHOR

Andrew Solomon <andrew@geekuni.com>

# COPYRIGHT

Copyright 2014- Andrew Solomon

# ACKNOWLEDGEMENT

Built by Dist::Milla

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO
