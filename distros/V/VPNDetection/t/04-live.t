use strict;
use warnings;

use Test::More;
use VPNDetection;

# Hits production, so it costs quota and is skipped by default:
#
#   VPNDETECTION_LIVE=1 ./scripts/test.sh t/04-live.t
#
# It exists for the one claim a stub cannot make honestly: that a lookup without
# a key really does omit the fields a key adds rather than answering false.
plan skip_all => 'set VPNDETECTION_LIVE=1 to run the live checks'
    unless $ENV{VPNDETECTION_LIVE};

my $client = VPNDetection->new(
    $ENV{VPNDETECTION_API_KEY} ? (api_key => $ENV{VPNDETECTION_API_KEY}) : (),
);

subtest 'a known VPN address' => sub {
    my $result = $client->lookup('45.83.91.1');
    is($result->ip, '45.83.91.1', 'the address comes back normalized');
    is($result->is_vpn, 1, 'flagged as VPN infrastructure');
    is($result->is_bogon, 0, 'served rather than computed');
};

subtest 'an ordinary public address without a key' => sub {
    plan skip_all => 'a key raises the plan, so the shape without one no longer applies'
        if $ENV{VPNDETECTION_API_KEY};

    my $result = $client->lookup('1.1.1.1');
    is($result->is_vpn, 0, 'not VPN infrastructure');
    is($result->has('is_hosting'), 0, 'the hosting flag is ABSENT without a key');
    is($result->is_hosting, undef, 'so it reads as undef, not as false');
    is($result->is_hosting // 0, 0, 'and as false only when you ask for that');
    is($result->has('vpn'), 0, 'and so is the VPN detail');
};

subtest 'a batch mixes served and local answers' => sub {
    # A client of its own and no cache, so no answer comes from the lookups above.
    my $fresh = VPNDetection->new(
        cache_size => 0,
        $ENV{VPNDETECTION_API_KEY} ? (api_key => $ENV{VPNDETECTION_API_KEY}) : (),
    );
    my $answers = $fresh->lookup_batch(['45.83.91.1', '10.0.0.1', '45.83.91.1']);
    is(scalar keys %$answers, 2, 'the duplicate collapsed');
    is($answers->{'10.0.0.1'}->is_bogon, 1, 'the local answer');
    if ($ENV{VPNDETECTION_API_KEY}) {
        is($answers->{'45.83.91.1'}->is_vpn, 1, 'the served answer');
        return;
    }
    # POST /batch needs a key on a paid plan, so without one every address sent to it is refused.
    my $refused = $answers->{'45.83.91.1'};
    isa_ok($refused, 'VPNDetection::Error');
    is($refused->kind, 'unauthorized', 'a batch without a key is refused');
    is($refused->status, 401, 'with a 401');
};

done_testing();
