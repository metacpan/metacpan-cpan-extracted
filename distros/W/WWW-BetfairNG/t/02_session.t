#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 35;

# Tests of session methods NOT requiring internet connection
# ==========================================================

# Load Module
BEGIN { use_ok('WWW::BetfairNG') };
# Create Object w/o attributes
my $bf = new_ok('WWW::BetfairNG');
# Check all session methods exist
my @methods = qw/login interactiveLogin logout keepAlive/;
can_ok('WWW::BetfairNG', @methods);
# Test interactiveLogin
ok(!$bf->interactiveLogin(),                 "InteractiveLogin fails with no parameters");
is($bf->error(), "Username and Password Required", "No parameter error message OK");
ok(!$bf->interactiveLogin(username=>'username', password=>'password'),
                                             "InteractiveLogin fails with no hashref");
is($bf->error(), "Parameters must be a hash ref or anonymous hash",
                                             "Not a hash error message OK");
ok(!$bf->interactiveLogin({username=>'username', passwurd=>'password'}),
                                             "InteractiveLogin fails with bad params");
is($bf->error(), "Username and Password Required",
                                             "Bad params error message OK");
ok(!$bf->interactiveLogin({username=>'username'}),
                                             "InteractiveLogin fails with missing params");
is($bf->error(), "Username and Password Required",
                                             "Missing params error message OK");
# Test login
ok(!$bf->login(),                                  "Login fails with no parameters");
is($bf->error(), "Username and Password Required", "No parameter error message OK");
ok(!$bf->login(username=>'username', password=>'password'),
                                                   "Login fails with no hashref");
is($bf->error(), "Parameters must be a hash ref or anonymous hash",
                                                   "Not a hash error message OK");
ok(!$bf->login({username=>'username', passwurd=>'password'}),
                                                   "Login fails with bad params");
is($bf->error(), "Username and Password Required",
                                                   "Bad params error message OK");
ok(!$bf->login({username=>'username'}),
                                                   "Login fails with missing params");
is($bf->error(), "Username and Password Required",
                                                   "Missing params error message OK");
ok(!$bf->login({username=>'username', password=>'password'}),
                                                   "Login fails with no cert");
is($bf->error(), "SSL Client Certificate Required",
                                                   "No cert error message OK");
is($bf->ssl_cert('certfile'), 'certfile',          "Cert file added");
ok(!$bf->login({username=>'username', password=>'password'}),
                                                   "Login fails with no ssl key");
is($bf->error(), "SSL Client Key Required",
                                                   "No ssl key error message OK");
is($bf->ssl_key('keyfile'), 'keyfile',             "SSL key file added");
ok(!$bf->login({username=>'username', password=>'password'}),
                                        "Login fails with invalid key and cert files");
like($@, qr/SSL_cert_file certfile/,               "Check invalid key and cert files");
# Test logout
ok(!$bf->logout(),                                 "Logout fails with no session");
is($bf->error(), "Not logged in",                  "No session error message OK");
# Test keepAlive
is($bf->session(undef), undef,                     "Unset session token");
ok(!$bf->keepAlive(),                              "keepAlive fails with no session");
is($bf->error(), "Not logged in",                  "No session error message OK");
is($bf->session('session_token'), 'session_token', "Set session token");
ok(!$bf->keepAlive(),                              "keepAlive fails with no app key");
is($bf->error(), "No application key set",         "No app key error message OK");
