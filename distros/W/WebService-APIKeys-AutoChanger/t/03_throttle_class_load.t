use strict;
use warnings;
use WebService::APIKeys::AutoChanger;
use Test::More tests => 4;


{ 
    my $changer = WebService::APIKeys::AutoChanger->new;
    isa_ok( $changer, 'WebService::APIKeys::AutoChanger' );
    $changer->set(
        api_keys => [
            'aaaaaaaaaaaaaaaaaaa', 'bbbbbbbbbbbbbbbbbbb',
            'ccccccccccccccccccc',
        ]
    );
    isa_ok( $changer->throttle, 'Data::Valve' );
}

{ 
    my $changer = WebService::APIKeys::AutoChanger->new;
    isa_ok( $changer, 'WebService::APIKeys::AutoChanger' );
    $changer->set(
        api_keys => [
            'aaaaaaaaaaaaaaaaaaa', 'bbbbbbbbbbbbbbbbbbb',
            'ccccccccccccccccccc',
        ],
        throttle_class => 'Data::Throttler'
    );
    isa_ok( $changer->throttle, 'Data::Throttler' );
}