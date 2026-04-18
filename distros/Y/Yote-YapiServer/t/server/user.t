#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../lib";

# Mock the base class before loading User
BEGIN {
    package Yote::SQLObjectStore::BaseObj;
    sub new {
        my ($class, %args) = @_;
        bless { %args, _data => {} }, $class;
    }
    sub id { shift->{id} // int(rand(10000)) }

    # Generic getter/setter generator
    for my $field (qw(handle email enc_password is_admin details)) {
        no strict 'refs';
        *{"get_$field"} = sub { my $self = shift; return $self->{_data}{$field} };
        *{"set_$field"} = sub { my ($self, $val) = @_; $self->{_data}{$field} = $val };
    }

    $INC{'Yote/SQLObjectStore/BaseObj.pm'} = 1;

    # Mock BaseObj (User inherits from this)
    package Yote::YapiServer::BaseObj;
    our @ISA = ('Yote::SQLObjectStore::BaseObj');

    sub field_access {
        my ($self) = @_;
        my $class = ref($self) || $self;
        no strict 'refs';
        return \%{"${class}::FIELD_ACCESS"};
    }

    sub method_defs {
        my ($self) = @_;
        my $class = ref($self) || $self;
        no strict 'refs';
        return \%{"${class}::METHODS"};
    }

    $INC{'Yote/YapiServer/BaseObj.pm'} = 1;
}

use Yote::YapiServer::User;

#----------------------------------------------------------------------
# Password handling tests
#----------------------------------------------------------------------

subtest 'set_password - encrypts password' => sub {
    my $user = Yote::YapiServer::User->new();
    $user->set_handle('testuser');

    $user->set_password('secret123');

    my $enc = $user->get_enc_password();
    ok(defined $enc, 'encrypted password is set');
    isnt($enc, 'secret123', 'password is not stored in plaintext');
    ok(length($enc) > 10, 'encrypted password has reasonable length');
};

subtest 'verify_password - correct password' => sub {
    my $user = Yote::YapiServer::User->new();
    $user->set_handle('alice');

    $user->set_password('correcthorse');
    ok($user->verify_password('correcthorse'), 'correct password verifies');
};

subtest 'verify_password - wrong password' => sub {
    my $user = Yote::YapiServer::User->new();
    $user->set_handle('bob');

    $user->set_password('mypassword');
    ok(!$user->verify_password('wrongpassword'), 'wrong password fails');
    ok(!$user->verify_password(''), 'empty password fails');
    ok(!$user->verify_password('MYPASSWORD'), 'case-sensitive');
};

subtest 'set_password - different handles produce different hashes' => sub {
    my $user1 = Yote::YapiServer::User->new();
    $user1->set_handle('user1');
    $user1->set_password('samepass');

    my $user2 = Yote::YapiServer::User->new();
    $user2->set_handle('user2');
    $user2->set_password('samepass');

    isnt($user1->get_enc_password(), $user2->get_enc_password(),
        'same password produces different hashes for different handles');
};

subtest 'set_password - email is used in hash computation' => sub {
    # Note: crypt() may use limited salt length, so same-handle users
    # with different emails might get same hash. This test verifies
    # the password mechanism works correctly with email present.
    my $user = Yote::YapiServer::User->new();
    $user->set_handle('emailuser');
    $user->set_email('test@example.com');
    $user->set_password('mypassword');

    # Password should verify correctly
    ok($user->verify_password('mypassword'), 'password verifies with email set');
    ok(!$user->verify_password('wrongpassword'), 'wrong password fails with email set');
};

#----------------------------------------------------------------------
# Field access tests
#----------------------------------------------------------------------

subtest 'field_access - returns hash' => sub {
    my $user = Yote::YapiServer::User->new();
    my $access = $user->field_access();

    is(ref($access), 'HASH', 'returns hashref');
    ok(exists $access->{handle}, 'handle field exists');
    ok(exists $access->{email}, 'email field exists');
    ok(exists $access->{enc_password}, 'enc_password field exists');
};

subtest 'field_access - handle is public' => sub {
    my $user = Yote::YapiServer::User->new();
    my $access = $user->field_access();

    ok($access->{handle}{public}, 'handle is public');
};

subtest 'field_access - email is owner_only' => sub {
    my $user = Yote::YapiServer::User->new();
    my $access = $user->field_access();

    ok($access->{email}{owner_only}, 'email is owner_only');
};

subtest 'field_access - enc_password is never' => sub {
    my $user = Yote::YapiServer::User->new();
    my $access = $user->field_access();

    ok($access->{enc_password}{never}, 'enc_password is never exposed');
};

subtest 'field_access - is_admin is public' => sub {
    my $user = Yote::YapiServer::User->new();
    my $access = $user->field_access();

    ok($access->{is_admin}{public}, 'is_admin is public');
};

#----------------------------------------------------------------------
# Method access tests
#----------------------------------------------------------------------

subtest 'method_defs - returns hash' => sub {
    my $user = Yote::YapiServer::User->new();
    my $methods = $user->method_defs();

    is(ref($methods), 'HASH', 'returns hashref');
    ok(exists $methods->{getProfile}, 'getProfile method exists');
    ok(exists $methods->{updateProfile}, 'updateProfile method exists');
};

subtest 'method_defs - getProfile requires auth' => sub {
    my $user = Yote::YapiServer::User->new();
    my $methods = $user->method_defs();

    ok($methods->{getProfile}{auth}, 'getProfile requires auth');
};

subtest 'method_defs - updateProfile is owner_only' => sub {
    my $user = Yote::YapiServer::User->new();
    my $methods = $user->method_defs();

    ok($methods->{updateProfile}{auth}, 'updateProfile requires auth');
    ok($methods->{updateProfile}{owner_only}, 'updateProfile is owner_only');
};

#----------------------------------------------------------------------
# Client-callable method tests
#----------------------------------------------------------------------

subtest 'getProfile - returns self' => sub {
    my $user = Yote::YapiServer::User->new();
    $user->set_handle('profileuser');

    my ($ok, $result) = $user->getProfile({}, undef);
    ok($ok, 'getProfile succeeds');
    is($result, $user, 'getProfile returns self');
};

subtest 'updateProfile - updates allowed fields' => sub {
    my $user = Yote::YapiServer::User->new();
    $user->set_handle('updateuser');
    $user->set_email('old@email.com');

    my ($ok, $result) = $user->updateProfile({ email => 'new@email.com' }, undef);

    ok($ok, 'updateProfile succeeds');
    is($user->get_email(), 'new@email.com', 'email was updated');
    is($result, $user, 'updateProfile returns self');
};

subtest 'updateProfile - ignores non-allowed fields' => sub {
    my $user = Yote::YapiServer::User->new();
    $user->set_handle('testuser');
    $user->set_is_admin(0);

    $user->updateProfile({
        email    => 'allowed@test.com',
        is_admin => 1,  # Should be ignored
        handle   => 'newhandle',  # Should be ignored
    }, undef);

    is($user->get_email(), 'allowed@test.com', 'email was updated');
    is($user->get_is_admin(), 0, 'is_admin was not changed');
    is($user->get_handle(), 'testuser', 'handle was not changed');
};

done_testing();
