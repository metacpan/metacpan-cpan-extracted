use Test::More;

use_ok('Zonemaster::LDNS');

SKIP: {
    my $can_use_threads = eval 'use threads; 1';

    skip 'no network or no threads', 4 unless $ENV{TEST_WITH_NETWORK} and $can_use_threads;

    my $resolver = Zonemaster::LDNS->new('8.8.8.8');
    isa_ok($resolver, 'Zonemaster::LDNS');
    my $rr = Zonemaster::LDNS::RR->new('www.iis.se.		60	IN	A	91.226.36.46');
    isa_ok($rr, 'Zonemaster::LDNS::RR::A');
    my $p = $resolver->query('www.google.com');
    isa_ok($p, 'Zonemaster::LDNS::Packet');
    my $rrlist = $p->all;
    isa_ok($rrlist, 'Zonemaster::LDNS::RRList');

    threads->create( sub {
        my $p = $resolver->query('www.lysator.liu.se');
        if (not ($p and ref($p) and ref($p) eq 'Zonemaster::LDNS::Packet')) {
            die "Something is wrong here";
        }
    } ) for 1..5;

    $_->join for threads->list;
}

done_testing;
