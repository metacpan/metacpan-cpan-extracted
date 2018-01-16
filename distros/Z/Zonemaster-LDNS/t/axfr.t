use Test::More;
use Test::Fatal;

BEGIN { use_ok( 'Zonemaster::LDNS' ) }

SKIP: {
    skip 'no network', 3 unless $ENV{TEST_WITH_NETWORK};

    my $res = Zonemaster::LDNS->new( '46.21.106.227' );
    my $res2 = Zonemaster::LDNS->new( '192.36.144.107' );

    my $counter = 0;
    my $return = $res->axfr( 'cyberpomo.com',
        sub {
            my ($rr) = @_;
            $counter += 1;
            if ($rr->type eq 'CNAME') {
                return 0;
            } else {
                return 1;
            }
        });
    ok(!$return, 'Terminated early');
    ok(($counter > 1), 'Saw more than one entry (' . $counter . ')');

    like( exception { $res2->axfr( 'iis.se', sub { return 1 })}, qr/NOTAUTH/, 'Expected exception');
}

done_testing;
