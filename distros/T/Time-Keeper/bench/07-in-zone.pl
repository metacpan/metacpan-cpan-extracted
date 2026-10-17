#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use DateTime;
my $tz = DateTime::TimeZone->new(name => 'Asia/Tokyo');
my ($t, $dt) = (Time::Keeper->from_epoch(1760000000), DateTime->from_epoch(epoch => 1760000000));
mark('in_zone, by name; DateTime given the zone object', rate(sub { $t->in_zone('Asia/Tokyo') }), rate(sub { $dt->clone->set_time_zone($tz) }, 'DateTime'), 10, 'DateTime');
done();
