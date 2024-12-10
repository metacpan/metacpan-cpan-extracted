use strict;
use warnings;
use Test::More;

use MIME::Base64;
use Test::Differences;
use Test::Fatal;

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

is( scalar $p->question, 1,   'One RR in question section' );
isa_ok( ($p->question)[0], 'Zonemaster::LDNS::RR' );

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

subtest "Answer section" => sub {
    # Parse a packet with a single incomplete MX record
    my $data = decode_base64( "EjSFgAABAAIAAAAAB2V4YW1wbGUCc2UAAA8AAcAMAA8AAQABUYAAAgAKwAwAAQABAAFRgAAEwAACAQ==");
    my $p = Zonemaster::LDNS::Packet->new_from_wireformat( $data );

    my $rr_count = scalar $p->answer;

    is $rr_count, 1, "keep complete RRs but ignore incomplete ones";

    # Retrieve section as a Zonemaster::LDNS::RRList object
    my $rrlist = $p->answer_rrlist;
    is( $rrlist->count, 1,      'One RR in RRList' );
    ok( $rrlist->string,        'example.se. 86400 IN A 192.0.2.1');
    isa_ok( $rrlist->pop,       'Zonemaster::LDNS::RR' );
};

subtest "Authority section" => sub {
    # Parse a packet with a single incomplete MX record
    my $data = decode_base64( "EjSFgAABAAAAAgAAB2V4YW1wbGUCc2UAAA8AAcAMAA8AAQABUYAAAgAKwAwAAQABAAFRgAAEwAACAQ==" );
    my $p = Zonemaster::LDNS::Packet->new_from_wireformat( $data );

    my $rr_count = scalar $p->authority;

    is $rr_count, 1, "keep complete RRs but ignore incomplete ones";

    # Retrieve section as a Zonemaster::LDNS::RRList object
    my $rrlist = $p->authority_rrlist;
    is( $rrlist->count, 1,      'One RR in RRList' );
    ok( $rrlist->string,        'example.se. 86400 IN A 192.0.2.1');
    isa_ok( $rrlist->pop,       'Zonemaster::LDNS::RR' );
};

subtest "Additional section" => sub {
    # Parse a packet with a single incomplete MX record
    my $data = decode_base64( "EjSFgAABAAAAAAACB2V4YW1wbGUCc2UAAA8AAcAMAA8AAQABUYAAAgAKwAwAAQABAAFRgAAEwAACAQ==" );
    my $p = Zonemaster::LDNS::Packet->new_from_wireformat( $data );

    my $rr_count = scalar $p->additional;

    is $rr_count, 1, "keep complete RRs but ignore incomplete ones";

    # Retrieve section as a Zonemaster::LDNS::RRList object
    my $rrlist = $p->additional_rrlist;
    is( $rrlist->count, 1,      'One RR in RRList' );
    ok( $rrlist->string,        'example.se. 86400 IN A 192.0.2.1');
    isa_ok( $rrlist->pop,       'Zonemaster::LDNS::RR' );
};

subtest "All sections" => sub {
    my $p = Zonemaster::LDNS::Packet->new( 'example.se', 'SOA', 'IN' );

    my $rrlist = $p->question_rrlist();
    is( $rrlist->count, 1,   'One RR in RRList' );
    isa_ok( $rrlist->get(0), 'Zonemaster::LDNS::RR' );

    $p->unique_push( 'authority',  Zonemaster::LDNS::RR->new_from_string( 'example.se. IN SOA dnsmaster.example.se hostmaster.example.se 2024000000 7200 1800 2419200 5400' ) );
    $p->unique_push( 'answer',     Zonemaster::LDNS::RR->new_from_string( 'example.se. IN NS ns1.example.se' ) );
    $p->unique_push( 'additional', Zonemaster::LDNS::RR->new_from_string( 'ns1.example.se. IN A 192.0.2.1' ) );

    $rrlist = $p->all;
    is( $rrlist->count, 3,      'Three RRs in RRList' );
    while ( my $rr = $rrlist->pop ) {
        isa_ok( $rr, 'Zonemaster::LDNS::RR' );
    }
};

done_testing();
