use warnings;
use strict;
use ZWave::Protocol;
use Test::More;
use Log::Log4perl qw(:easy);

# Log::Log4perl->easy_init($DEBUG);

my $zwave = ZWave::Protocol->new;

my $cks = $zwave->checksum( 1, 2, 3 );
is $cks, 0xfe, "checksum";
    
SKIP: {
    if( !$ENV{ LIVE_TESTS } ) {
        skip "LIVE_TESTS not set" . $zwave->device, 2;
    }

    $zwave->connect;

    my $node_id = 3;
    my $state   = 255; # "on"
    
    my $rc = $zwave->payload_transmit( 0, 0x13, $node_id, 
                      0x03, 0x20, 0x01, $state, 0x05 );
    
    is $rc, 1, "on";

    sleep 1;
    $state = 0;
    $rc = $zwave->payload_transmit( 0, 0x13, $node_id, 
                      0x03, 0x20, 0x01, $state, 0x05 );
    is $rc, 1, "off";
}

done_testing;
