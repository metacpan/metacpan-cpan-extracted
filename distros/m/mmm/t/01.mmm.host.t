use strict;
use warnings;

use Test::More tests => 9;

use_ok('MMM::Host');

{
    my $mi = MMM::Host->new(
        hostname    => 'foo.com',
        city        => 'Paris',
        geolocation => '3.5,48.0',
    );
    isa_ok( $mi, 'MMM::Host' );
    is( $mi->hostname, 'foo.com', 'can get hostname' );
    ok(
        eq_array( [ $mi->geo ], [ '48.0', '3.5' ] ),
        'properly parse latitude/longitude'
    );
}

ok( !MMM::Host->new(), 'Deny to build invalid mirror entry' );
ok( MMM::Host->new( hostname => 'foo.com' ), 'Minimum info is hostname' );

{
    my $mi = MMM::Host->new(
        hostname    => 'foo.com',
        geolocation => '90,0',
    );
    ok(
        $mi->distance(
            MMM::Host->new( hostname => 'bar.com', geolocation => '90,0', )
          ) == 0,
        'host distance calculation'
    );
    ok(
        $mi->distance(
            MMM::Host->new( hostname => 'bar.com', geolocation => '90,90', )
          ) == 90,
        'host distance calculation'
    );
    ok(
        $mi->distance(
            MMM::Host->new( hostname => 'bar.com', geolocation => '0,0', )
          ) == 90,
        'host distance calculation'
    );
}
