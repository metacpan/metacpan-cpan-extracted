use Test::More;
use Test::Fatal;

use strict;
use warnings;

use_ok('Zonemaster::LDNS');

my $p = new_ok('Zonemaster::LDNS::Packet' => ['www.example.org', 'SOA', 'IN']);

foreach my $r (qw[NOERROR FORMERR SERVFAIL NXDOMAIN NOTIMPL REFUSED YXDOMAIN YXRRSET NXRRSET NOTAUTH NOTZONE]) {
    is($p->rcode($r), $r, $r);
}
like( exception {$p->rcode('gurksallad')}, qr/Unknown RCODE: gurksallad/, 'Expected exception' );

foreach my $r (qw[QUERY IQUERY STATUS NOTIFY UPDATE]) {
    is($p->opcode($r), $r, $r);
}
like( exception {$p->opcode('gurksallad')}, qr/Unknown OPCODE: gurksallad/, 'Expected exception' );

is($p->id(4711), 4711, 'Setting ID');
is($p->id(2147488359), 4711, 'Wraparound ID');

is($p->querytime(4711), 4711, 'Setting query time');
is($p->querytime(2147488359), 2147488359, 'Setting larger query time');

is($p->answerfrom, undef, 'No answerfrom');
$p->answerfrom('127.0.0.1');
is($p->answerfrom, '127.0.0.1', 'Localhost');

subtest "croak when stringifying packet with malformed CAA" => sub {
    my $will_croak = sub {
        # Constructing a synthetic packet that would have the following string
        # representation in dig-like format:
        #
        # ;; ->>HEADER<<- opcode: QUERY, rcode: NOERROR, id: 13944
        # ;; flags: qr aa ; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0
        # ;; QUESTION SECTION:
        # ;; bad-caa.example.       IN      CAA
        #
        # ;; ANSWER SECTION:
        # bad-caa.example.  3600    IN      CAA     \# 4 C0000202
        #
        # ;; AUTHORITY SECTION:
        #
        # ;; ADDITIONAL SECTION:
        my $packet_bin = pack(
            'H*',
            '367884000001000100000000' . # header
            '076261642d636161076578616d706c650001010001' . # question
            'c00c0101000100000e100004c0000202' # bad answer
        );

        my $packet = Zonemaster::LDNS::Packet->new_from_wireformat( $packet_bin );

        # This must croak
        $packet->string;
    };
    like( exception { $will_croak->() }, qr/^Failed to convert packet to string/ );
};

done_testing();
