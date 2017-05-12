use strict;
use warnings;
use WebService::APIKeys::AutoChanger;
use Test::More tests => 4; 

my $changer = WebService::APIKeys::AutoChanger->new(
    api_keys => [
        'aaaaaaaaaaaaaaaaaaa',
        'bbbbbbbbbbbbbbbbbbb',
        'ccccccccccccccccccc',
    ],
    throttle_class  => 'Data::Valve',
    throttle_config => {
        max_items => 10,
        interval  => 10,
    }
);


is_deeply(
    $changer->api_keys => [
        'aaaaaaaaaaaaaaaaaaa',
        'bbbbbbbbbbbbbbbbbbb',
        'ccccccccccccccccccc',
    ], "api_keys OK"
);
isa_ok( $changer->throttle, 'Data::Valve', "throttle OK" );
is( $changer->throttle->max_items, 10, "max_items OK" );
is( $changer->throttle->interval, 10, "interval OK" );
