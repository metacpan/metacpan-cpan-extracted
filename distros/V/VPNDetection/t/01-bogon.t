use strict;
use warnings;

use lib 't/lib';

use Test::More;
use VPNDetection 'is_bogon';
use VPNDetectionTest;

my $cases = VPNDetectionTest::corpus()->{isBogon};
plan tests => 2 * @$cases + 4;

# Membership cases, plus boundary pairs that pin the prefix WIDTH, so a mask one
# bit too wide or too narrow fails here rather than in production.
my $client = VPNDetection->new;
for my $case (@$cases) {
    my $want = $case->{expect} ? 1 : 0;
    is(is_bogon($case->{ip}), $want, "$case->{ip} ($case->{why})");
    is($client->is_bogon($case->{ip}), $want, "$case->{ip} via the client");
}

is(is_bogon('10.0.0.0/8'), 0, 'a CIDR is not an address');
is(is_bogon('notanip'), 0, 'junk is not a bogon');
is(is_bogon(''), 0, 'the empty string is not a bogon');
is(VPNDetection::is_bogon('::ffff:10.0.0.1'), 1,
    'a mapped address is judged as the IPv4 address it carries');
