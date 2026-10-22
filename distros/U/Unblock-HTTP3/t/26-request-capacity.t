use strict;
use warnings;
use Test2::V0;
use Scalar::Util qw(refaddr);

use Unblock::HTTP3::Client;
use Uniform::HTTP::Request;

{
    package CreditTest::Native;
    sub uniform_request_field_section_size { 24 }
    sub uniform_trailer_field_section_size { 0 }

    package CreditTest::Quic;
    sub new { bless { openings => 0 }, shift }
    sub open_bidi_stream { $_[0]{openings}++; return }
}

my $quic = CreditTest::Quic->new;
my @woken;
my $client = bless {
    role => 'client',
    started => 1,
    failed => 0,
    shutdown_started => 0,
    remote_shutdown_id => undef,
    quic => $quic,
    native => bless({}, 'CreditTest::Native'),
    peer_max_field_section_size => 65536,
    request_credit_blocked => 0,
    on_request_available => sub { push @woken, $_[0] },
}, 'Unblock::HTTP3::Client';

my $request = Uniform::HTTP::Request->new(
    method => 'GET',
    scheme => 'https',
    authority => 'credit.example',
    target => '/',
);
ok(!defined $client->_submit_request($request, 0),
    'QUIC bidi credit exhaustion rejects submission before wire output');
is($quic->{openings}, 1, 'only one QUIC open was attempted');
ok($client->{request_credit_blocked}, 'engine remembers unsent admission failure');
ok($request->is_mutable, 'unsent request remains mutable');

$client->_request_stream_available('uni');
is(scalar @woken, 0, 'unidirectional stream availability does not admit requests');
ok($client->{request_credit_blocked}, 'uni event does not clear bidi block');

$client->_request_stream_available('bidi');
is(scalar @woken, 1, 'one notification when bidi credit might have returned');
is(refaddr($woken[0]), refaddr($client), 'callback receives real HTTP3 Client');
ok(!$client->{request_credit_blocked}, 'wake clears outstanding block flag');
$client->_request_stream_available('bidi');
is(scalar @woken, 1, 'event is one-shot until another refusal');

ok(!defined $client->_submit_request($request, 0),
    'another refused request may re-arm waiting state');
ok($client->{request_credit_blocked}, 'credit wait armed again');
$client->{shutdown_started} = 1;
$client->_request_stream_available('bidi');
is(scalar @woken, 1, 'shutdown suppresses stale capacity notification');
$client->{shutdown_started} = 0;
$client->{remote_shutdown_id} = 0;
$client->_request_stream_available('bidi');
is(scalar @woken, 1, 'remote GOAWAY suppresses stale capacity notification');

$client->{remote_shutdown_id} = undef;
$client->{failed} = 1;
$client->_request_stream_available('bidi');
is(scalar @woken, 1, 'failed connection cannot announce request capacity');

my $server = bless {
    %$client, role => 'server', failed => 0, request_credit_blocked => 1,
}, 'Unblock::HTTP3::Connection';
$server->_request_stream_available('bidi');
is(scalar @woken, 1, 'server never emits client admission notification');

my $other = bless {
    %$client, role => 'client', failed => 0, remote_shutdown_id => undef,
    request_credit_blocked => 1, on_request_available => undef,
}, 'Unblock::HTTP3::Client';
ok(eval { $other->_request_stream_available('bidi'); 1 },
    'standalone client without callback still handles capacity event');

done_testing;
