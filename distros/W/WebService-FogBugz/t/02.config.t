#!/usr/bin/perl -w
use strict;

use Test::More tests => 18;
use WebService::FogBugz::Config;

my $email    = 'blah';
my $password = 'blah';
my $base_url = 'blah';
my $token    = 'blah';

my $fogbugz;
eval {
    $fogbugz = WebService::FogBugz::Config->new(
        email    => $email,
        password => $password,
        base_url => $base_url
    );
};
is $@, '', 'config ok';
is(ref($fogbugz), 'WebService::FogBugz::Config', 'reference');
SKIP: {
    skip "local config found, cannot test", 4   if($fogbugz->file);
    is($fogbugz->base_url, $base_url, 'param base_url');
    is($fogbugz->email,    $email,    'param email');
    is($fogbugz->password, $password, 'param password');
    is($fogbugz->token,    undef,     'param token');
}

my $test_file = 't/data/config01.txt';

eval {
    $fogbugz = WebService::FogBugz::Config->new(
        config   => $test_file
    );
};
is $@, '', 'config ok';
is(ref($fogbugz), 'WebService::FogBugz::Config', 'reference');
SKIP: {
    skip "local config found, cannot test", 4   if($fogbugz->file ne $test_file);
    is($fogbugz->base_url, $base_url, 'param base_url');
    is($fogbugz->email,    $email,    'param email');
    is($fogbugz->password, $password, 'param password');
    is($fogbugz->token,    undef,     'param token');
}

$test_file = 't/data/config02.txt';

eval {
    $fogbugz = WebService::FogBugz::Config->new(
        config   => $test_file
    );
};
is $@, '', 'config ok';
is(ref($fogbugz), 'WebService::FogBugz::Config', 'reference');
SKIP: {
    skip "local config found, cannot test", 4   if($fogbugz->file ne $test_file);
    is($fogbugz->base_url, $base_url, 'param base_url');
    is($fogbugz->email,    undef,     'param email');
    is($fogbugz->password, undef,     'param password');
    is($fogbugz->token,    $token,    'param token');
}
