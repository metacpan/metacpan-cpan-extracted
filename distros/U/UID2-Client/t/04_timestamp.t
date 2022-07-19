use strict;
use warnings;

use Test::More;

use UID2::Client::Timestamp;

my $t = UID2::Client::Timestamp->now;
isa_ok $t, 'UID2::Client::Timestamp';
my $time = time;
my $second = $t->get_epoch_second;
cmp_ok $second, '<', $time + 5;
cmp_ok $second, '>', $time - 5;
ok !$t->is_zero;
ok(UID2::Client::Timestamp->from_epoch_second(0)->is_zero);

is $t->get_epoch_second, int($t->get_epoch_milli / 1000);
is(UID2::Client::Timestamp->from_epoch_milli($t->get_epoch_milli)->get_epoch_milli, $t->get_epoch_milli);
is(UID2::Client::Timestamp->from_epoch_second($t->get_epoch_second)->get_epoch_second, $t->get_epoch_second);

is $t->add_seconds(42)->get_epoch_second, $t->get_epoch_second + 42;
is $t->add_days(42)->get_epoch_second, $t->get_epoch_second + (42 * 24 * 60 * 60);

done_testing;
