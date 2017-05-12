use strict;
use warnings;

use Test::More 0.88;

use WebService::MinFraud::Record::Device;

my $device_id = 'ECE205B0-BE16-11E5-B83F-FE035C37265F';
my $device    = WebService::MinFraud::Record::Device->new(
    confidence => 99.0,
    id         => $device_id,
    last_seen  => '2016-06-08T14:16:38Z',
);

is( $device->confidence, 99,                     'device confidence' );
is( $device->id,         $device_id,             'device id' );
is( $device->last_seen,  '2016-06-08T14:16:38Z', 'device last_seen' );

done_testing;
