#! perl

use strict;
use warnings;

use Test::More;

use Time::HiRes 'time';
use UUID::V7 ':all';

use POSIX::RT::Clock;
my $clock = POSIX::RT::Clock->new('realtime');
my $resolution = $clock->get_resolution * 1_000_000_000;
diag "Clock resolution is: $resolution ns";
my $significance = $resolution < 1000 ? 18 : 17; # Can't test full length without sufficient precision.

my @unsorted  = map { substr generate_uuid_v7(), 0, $significance } 0..999_999;
my @sorted = sort @unsorted;
is_deeply(\@unsorted, \@sorted, 'UUID heads came in sorted order');

my $now = time;
my $uuid = generate_uuid_v7;
my $time = extract_uuid_v7_time($uuid);
ok($time - $now > 0.0, 'Times are equivalentish');
ok($time - $now < 0.1, 'Times are equivalentish');

my $binary = uuid_string_to_binary($uuid);
my $uuid2 = uuid_binary_to_string($binary);
is($uuid2, $uuid, 'to/from binary round-trips');
ok(is_uuid_v7($uuid), 'Is a UUIDv7');

done_testing;
