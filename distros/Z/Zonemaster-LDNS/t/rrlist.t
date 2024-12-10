use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Differences;

use Zonemaster::LDNS;

subtest "Empty RRList" => sub {
    my $empty_impl = Zonemaster::LDNS::RRList->new();
    my $empty_expl = Zonemaster::LDNS::RRList->new([]);
    my $singleton = Zonemaster::LDNS::RRList->new([
        Zonemaster::LDNS::RR->new_from_string('test. 0 IN TXT "hello"')
    ]);

    isa_ok($empty_impl, 'Zonemaster::LDNS::RRList');
    isa_ok($empty_expl, 'Zonemaster::LDNS::RRList');
    isa_ok($singleton, 'Zonemaster::LDNS::RRList');

    # We really want to make sure that new() and new([]) have the same
    # semantics.

    ok( $empty_impl eq $empty_expl, "two distinct empty RRLists are equal to each other" );
    ok( $empty_expl eq $empty_impl, "eq on two empty lists is commutative" );

    eq_or_diff( $empty_impl->string, '', "stringifying an implicitly empty list gives empty string" );
    eq_or_diff( $empty_expl->string, '', "stringifying an explicitly empty list gives empty string" );

    ok( $empty_impl ne $singleton, "the implicitly empty list isn’t equal to a non-empty one" );
    ok( $empty_expl ne $singleton, "the explicitly empty list isn’t equal to a non-empty one" );

    $singleton->pop();
    ok( $empty_impl eq $singleton, "now both lists are empty" );

    is( $empty_impl->count(), 0, "count() on implicitly empty list is 0" );
    is( $empty_expl->count(), 0, "count() on explicitly empty list is 0" );

    is( $empty_impl->get(0), undef, "get(0) on empty list gives undef" );
    is( $empty_impl->get(42), undef, "get(42) on empty list also gives undef" );

    ok( !$empty_impl->is_rrset(), "an empty list is not an RRset" );
    ok( !$empty_expl->is_rrset(), "an empty list is not an RRset" );
};

subtest "Good RRList" => sub {
    my $rr1 = Zonemaster::LDNS::RR->new_from_string( 'example. 10 IN NS ns1.example.' );
    my $rr2 = Zonemaster::LDNS::RR->new_from_string( 'example. 10 IN NS ns2.example.' );

    my $rrlist = Zonemaster::LDNS::RRList->new( [ $rr1, $rr2 ] );

    is( $rrlist->count, 2, 'Two in RRList' );
    eq_or_diff $rrlist->string,
               "example.\t10\tIN\tNS\tns1.example.\nexample.\t10\tIN\tNS\tns2.example.",
               'RRList string match';
    isa_ok( $rrlist->get(0), 'Zonemaster::LDNS::RR');
    isa_ok( $rrlist->get(0), 'Zonemaster::LDNS::RR::NS');

    my $rrlist_reversed = Zonemaster::LDNS::RRList->new( [ $rr2, $rr1 ] );

    ok( $rrlist eq $rrlist_reversed, 'Equal RRLists' );

    subtest "RRset" => sub {
        subtest "Same TTL and owner name" => sub {
            ok( $rrlist->is_rrset,    'Is a RRset with same TTL and owner name' );
        };

        subtest "Different CLASS" => sub {
            my $rr3 = Zonemaster::LDNS::RR->new_from_string( 'example. 10 CH NS ns3.example.' );
            my $rrlist2 = Zonemaster::LDNS::RRList->new( [ $rr1, $rr3 ] );
            ok( !$rrlist2->is_rrset,    'Is not a RRset with different CLASS' );
        };

        subtest "Different TYPE" => sub {
            my $rr3 = Zonemaster::LDNS::RR->new_from_string( 'example. 10 IN TXT ns3.example.' );
            my $rrlist2 = Zonemaster::LDNS::RRList->new( [ $rr1, $rr3 ] );
            ok( !$rrlist2->is_rrset,    'Is not a RRset with different TYPE' );
        };

        SKIP: {
            # Skipped due to a bug in LDNS, see https://github.com/NLnetLabs/ldns/pull/251
            skip "Further is_rrset() testing disabled due to an issue in LDNS", 1;

            subtest "Different TTL" => sub {
                my $rr3 = Zonemaster::LDNS::RR->new_from_string( 'example. 20 IN NS ns3.example.' );
                my $rrlist2 = Zonemaster::LDNS::RRList->new( [ $rr1, $rr3 ] );
                ok( !$rrlist2->is_rrset,    'Is not a RRset with different TTL' );
            };

            subtest "Case varying owner name" => sub {
                my $rr3 = Zonemaster::LDNS::RR->new_from_string( 'eXamPle. 20 IN NS ns3.example.' );
                my $rrlist2 = Zonemaster::LDNS::RRList->new( [ $rr2, $rr3 ] );
                ok( $rrlist2->is_rrset,    'Is a RRset with case varying owner names' );
            };
        }
    };

    my $rr3 = Zonemaster::LDNS::RR->new_from_string( 'example. 10 IN A 127.0.0.1' );

    ok( $rrlist->push( $rr3 ), 'Push OK' );
    is( $rrlist->count, 3,     'Three RRs in RRList' );
    isa_ok( $rrlist->get(2), 'Zonemaster::LDNS::RR');
    isa_ok( $rrlist->get(2), 'Zonemaster::LDNS::RR::A');

    is( $rrlist->get(3), undef, 'No RR here');

    while ( my $rr = $rrlist->pop ) {
        isa_ok( $rr, 'Zonemaster::LDNS::RR' );
    }
    is( $rrlist->count, 0, 'Zero RRs in RRList' );
    ok( !$rrlist->is_rrset, 'Is not a RRset' );

    is( $rrlist->get(0), undef, 'No RR here');
};

subtest "Bad RRList" => sub {
    my $rr1 = 'example. IN NS ns1.example.';
    my $rr2 = 'example. IN NS ns2.example.';

    my @rrs = ( $rr1, $rr2 );

    throws_ok { Zonemaster::LDNS::RRList->new( \@rrs ) } qr/Incorrect type in list/, 'crashes on incorrect type';
};

done_testing;
