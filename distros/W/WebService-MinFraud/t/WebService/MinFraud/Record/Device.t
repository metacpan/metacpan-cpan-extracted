use strict;
use warnings;

use Test::More 0.88;

use WebService::MinFraud::Record::Device;

my $device_id  = 'ECE205B0-BE16-11E5-B83F-FE035C37265F';
my $last_seen  = '2016-06-08T14:16:38Z';
my $local_time = '2018-04-03T17:01:40-07:00';
my $device     = WebService::MinFraud::Record::Device->new(
    confidence => 99.0,
    id         => $device_id,
    last_seen  => $last_seen,
    local_time => $local_time,
);

my %expect = (
    confidence => 99,
    id         => $device_id,
    last_seen  => $last_seen,
    local_time => $local_time,
);

for my $attr ( keys %expect ) {
    subtest $attr => sub {
        is( $device->$attr, $expect{$attr}, $attr );
        my $predicate = 'has_' . $attr;
        ok( $device->$predicate, $predicate );
    };
}

done_testing;
