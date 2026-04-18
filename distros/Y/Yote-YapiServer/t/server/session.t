#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../lib";

# Mock the base class before loading Session
BEGIN {
    package Yote::SQLObjectStore::BaseObj;
    sub new {
        my ($class, %args) = @_;
        bless { %args, _data => {} }, $class;
    }
    sub id { shift->{id} // int(rand(10000)) }
    sub get_exposed_objs {
        my $self = shift;
        $self->{_data}{exposed_objs} //= {};
        return $self->{_data}{exposed_objs};
    }
    sub get_expires { my $self = shift; return $self->{_data}{expires} }
    sub set_expires { my ($self, $val) = @_; $self->{_data}{expires} = $val }
    sub get_last_access { my $self = shift; return $self->{_data}{last_access} }
    sub set_last_access { my ($self, $val) = @_; $self->{_data}{last_access} = $val }
    $INC{'Yote/SQLObjectStore/BaseObj.pm'} = 1;
}

use Yote::YapiServer::Session;

#----------------------------------------------------------------------
# Token generation tests
#----------------------------------------------------------------------

subtest 'generate_token - format' => sub {
    my $token = Yote::YapiServer::Session->generate_token();

    ok(defined $token, 'token is defined');
    ok(length($token) > 40, 'token has sufficient length');
    like($token, qr/^[a-zA-Z0-9]+_\d+_[a-f0-9]{8}$/, 'token matches expected format');
};

subtest 'generate_token - uniqueness' => sub {
    my %tokens;
    for (1..100) {
        my $token = Yote::YapiServer::Session->generate_token();
        ok(!exists $tokens{$token}, "token $_ is unique");
        $tokens{$token} = 1;
    }
};

subtest 'generate_token - components' => sub {
    my $token = Yote::YapiServer::Session->generate_token();
    my @parts = split /_/, $token;

    is(scalar @parts, 3, 'token has 3 parts');
    is(length($parts[0]), 32, 'random part is 32 chars');
    like($parts[1], qr/^\d+$/, 'timestamp part is numeric');
    is(length($parts[2]), 8, 'signature part is 8 chars');
};

#----------------------------------------------------------------------
# Expiry calculation tests
#----------------------------------------------------------------------

subtest 'calculate_expiry - default duration' => sub {
    my $expiry = Yote::YapiServer::Session->calculate_expiry();

    ok(defined $expiry, 'expiry is defined');
    like($expiry, qr/^\d{4}-\d{2}-\d{2}$/, 'expiry is YYYY-MM-DD format');

    # Expiry should be in the future (greater than today)
    use Time::Piece;
    my $now = localtime->strftime("%Y-%m-%d");
    ok($expiry gt $now, 'expiry is in the future');
};

subtest 'calculate_expiry - custom duration' => sub {
    my $expiry_short = Yote::YapiServer::Session->calculate_expiry(7);
    my $expiry_long = Yote::YapiServer::Session->calculate_expiry(30);

    ok(defined $expiry_short, 'short expiry is defined');
    ok(defined $expiry_long, 'long expiry is defined');

    # Longer duration should produce later date
    ok($expiry_long gt $expiry_short, 'longer duration produces later date');
};

#----------------------------------------------------------------------
# Object capability tracking tests
#----------------------------------------------------------------------

subtest 'expose_object - basic' => sub {
    my $session = Yote::YapiServer::Session->new();

    my $mock_obj = bless { id => 42 }, 'MockObject';
    no warnings 'once';
    *MockObject::id = sub { shift->{id} };
    *MockObject::can = sub { $_[1] eq 'id' };

    my $id = $session->expose_object($mock_obj);

    is($id, 42, 'returns object id');
    ok($session->get_exposed_objs->{42}, 'object id is in exposed set');
};

subtest 'expose_object - undef and non-objects' => sub {
    my $session = Yote::YapiServer::Session->new();

    my $result = $session->expose_object(undef);
    ok(!defined $result, 'returns undef for undef input');

    $result = $session->expose_object("string");
    ok(!defined $result, 'returns undef for non-object');
};

subtest 'expose_objects - multiple' => sub {
    my $session = Yote::YapiServer::Session->new();

    my @objs = map { bless { id => $_ }, 'MockObject' } (10, 20, 30);
    my @ids = $session->expose_objects(@objs);

    is_deeply(\@ids, [10, 20, 30], 'returns all object ids');

    for my $id (10, 20, 30) {
        ok($session->get_exposed_objs->{$id}, "object $id is exposed");
    }
};

subtest 'can_access - object reference' => sub {
    my $session = Yote::YapiServer::Session->new();
    my $obj = bless { id => 100 }, 'MockObject';

    ok(!$session->can_access($obj), 'cannot access before exposed');

    $session->expose_object($obj);
    ok($session->can_access($obj), 'can access after exposed');
};

subtest 'can_access - numeric id' => sub {
    my $session = Yote::YapiServer::Session->new();
    my $obj = bless { id => 200 }, 'MockObject';

    $session->expose_object($obj);
    ok($session->can_access(200), 'can access by numeric id');
};

subtest 'can_access - _obj_ID format' => sub {
    my $session = Yote::YapiServer::Session->new();
    my $obj = bless { id => 300 }, 'MockObject';

    $session->expose_object($obj);
    ok($session->can_access('_obj_300'), 'can access by _obj_ID format');
    ok(!$session->can_access('_obj_999'), 'cannot access non-exposed _obj_ID');
};

subtest 'can_access - undef' => sub {
    my $session = Yote::YapiServer::Session->new();
    ok(!$session->can_access(undef), 'cannot access undef');
};

subtest 'revoke_access' => sub {
    my $session = Yote::YapiServer::Session->new();
    my $obj = bless { id => 400 }, 'MockObject';

    $session->expose_object($obj);
    ok($session->can_access($obj), 'can access after exposed');

    $session->revoke_access($obj);
    ok(!$session->can_access($obj), 'cannot access after revoked');
};

subtest 'revoke_access - by id' => sub {
    my $session = Yote::YapiServer::Session->new();
    my $obj = bless { id => 500 }, 'MockObject';

    $session->expose_object($obj);
    $session->revoke_access(500);
    ok(!$session->can_access($obj), 'cannot access after revoked by id');
};

subtest 'clear_exposed' => sub {
    my $session = Yote::YapiServer::Session->new();

    for my $id (1..10) {
        my $obj = bless { id => $id }, 'MockObject';
        $session->expose_object($obj);
    }

    is(scalar keys %{$session->get_exposed_objs}, 10, '10 objects exposed');

    $session->clear_exposed();
    is(scalar keys %{$session->get_exposed_objs}, 0, 'all objects cleared');
};

#----------------------------------------------------------------------
# Session expiration tests
#----------------------------------------------------------------------

subtest 'is_expired - not expired' => sub {
    my $session = Yote::YapiServer::Session->new();

    use Time::Piece;
    use Time::Seconds;
    my $future = localtime() + ONE_DAY;  # tomorrow
    $session->set_expires($future->strftime("%Y-%m-%d"));

    ok(!$session->is_expired(), 'session is not expired');
};

subtest 'is_expired - expired' => sub {
    my $session = Yote::YapiServer::Session->new();

    # Set a past date - need to call the mock properly
    $session->{_data}{expires} = "2020-01-01";
    ok($session->is_expired(), 'session is expired');
};

subtest 'is_expired - no expiry set' => sub {
    my $session = Yote::YapiServer::Session->new();
    ok($session->is_expired(), 'session with no expiry is expired');
};

#----------------------------------------------------------------------
# Touch / last access tests
#----------------------------------------------------------------------

subtest 'touch - updates last_access' => sub {
    my $session = Yote::YapiServer::Session->new();

    # Initially undefined (via mock data)
    ok(!$session->{_data}{last_access}, 'last_access initially undefined');

    $session->touch();
    my $access = $session->{_data}{last_access};

    ok(defined $access, 'last_access is set after touch');
    # The touch() method sets a datetime string
    like($access, qr/\d{4}-\d{2}-\d{2}/, 'last_access contains a date');
};

subtest 'refresh_expiry' => sub {
    my $session = Yote::YapiServer::Session->new();

    # Set an expired date
    $session->set_expires("2020-01-01");

    # Refresh should set a future date
    $session->refresh_expiry(30);
    my $new_expiry = $session->get_expires();

    # New expiry should be in the future (greater than 2020)
    ok($new_expiry gt "2020-01-01", 'expiry is now in the future');
    ok(!$session->is_expired(), 'not expired after refresh');
};

done_testing();
