use strict;
use warnings;

use Test::More;
use Zonemaster::LDNS;

SKIP: {
    skip 'no network', 1 unless $ENV{TEST_WITH_NETWORK};

    my $host = '192.134.4.1'; #ns1.nic.fr with nsid: ns1.th3.nic.fr
    my $expected_nsid = "ns1.th3.nic.fr";

    my $pkt = Zonemaster::LDNS::Packet->new('domain.example');
    $pkt->nsid; # set the NSID EDNS option
    my $res = Zonemaster::LDNS->new($host)->query_with_pkt($pkt);

    my $nsid = $res->get_nsid();

    is( $nsid, $expected_nsid, 'Correct NSID' );
};

done_testing();
