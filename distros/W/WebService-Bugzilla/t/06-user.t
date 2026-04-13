#!perl
use strict;
use warnings;
use Test::More import => [ qw( done_testing is isa_ok ok subtest ) ];
use lib 'lib', 't/lib';

use Test::Bugzilla;
use WebService::Bugzilla::User;

my $bz = Test::Bugzilla->new(
    base_url => 'http://bugzilla.example.com/rest',
    api_key  => 'abc',
);

subtest 'Get user' => sub {
    my $user = $bz->user->get(7);
    isa_ok($user, 'WebService::Bugzilla::User', 'get user returns user object');
    is($user->email, 'dev@example.com', 'user email is correct');
    is($user->login_name, 'developer', 'login_name mapped from API login key');
};

subtest 'Search users' => sub {
    my $users = $bz->user->search;
    isa_ok($users, 'ARRAY', 'search returns arrayref of users');
    is(scalar @{$users}, 1, 'one user returned');
};

subtest 'Create user' => sub {
    my $new_user = $bz->user->create(email => 'new@example.com');
    isa_ok($new_user, 'WebService::Bugzilla::User', 'create returns user object');
    is($new_user->id, 20, 'new user id is correct');
};

subtest 'Update user' => sub {
    my $updated_user = $bz->user->update(7, name => 'New Name');
    isa_ok($updated_user, 'WebService::Bugzilla::User', 'update returns user object');
    is($updated_user->id, 7, 'updated user id is preserved');
};

subtest 'Update user via instance method' => sub {
    my $user = $bz->user->get(7);
    my $inst_updated_user = $user->update(name => 'Instance Updated');
    isa_ok($inst_updated_user, 'WebService::Bugzilla::User', 'instance update returns user object');
};

subtest 'User authentication' => sub {
    my $auth = $bz->user->login(login => 'dev@example.com', password => 'secret');
    is($auth->{token}, 'abc123', 'authentication returns token');
};

subtest 'User logout' => sub {
    my $lo = $bz->user->logout;
    ok(defined $lo, 'logout returns defined value');
};

subtest 'Validate login' => sub {
    my $valid = $bz->user->valid_login(login => 'dev@example.com', token => 'abc123');
    ok($valid, 'valid_login returns true for valid credentials');
};

subtest 'Current user (whoami)' => sub {
    my $me = $bz->user->whoami;
    isa_ok($me, 'WebService::Bugzilla::User', 'whoami returns user object');
    is($me->id, 7, 'current user id is correct');
    is($me->login_name, 'developer', 'current user login_name is correct');
};

done_testing();
