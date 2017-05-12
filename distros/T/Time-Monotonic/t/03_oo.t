# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 6;
use Time::HiRes qw(usleep);
use Time::Monotonic;

my $mono = Time::Monotonic->new;
isa_ok($mono => 'Time::Monotonic', '$mono');

cmp_ok($$mono, '>', 0, 'deferencing ok');

my $t0 = $mono->now;
cmp_ok($t0, '>', 0, '$mono increments');

my $t1 = $mono->now;
cmp_ok($t1, '>', $t0, '$mono increments again');

my $t2 = Time::Monotonic->new(1);
cmp_ok($t2->now, '<', 0, 'offset applied successfully pre sleep');

my $t3 = Time::Monotonic->new(1/1_000);
usleep(2_000);
cmp_ok($t3->now, '>', 0, 'offset applied successfully post sleep');

done_testing;
