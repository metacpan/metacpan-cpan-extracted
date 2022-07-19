use strict;
use warnings;

use Test::More;

use UID2::Client::XS;
use UID2::Client::XS::Timestamp;

my $now = UID2::Client::XS::Timestamp->now();
isa_ok $now, 'UID2::Client::XS::Timestamp';
ok $now->get_epoch_second;
ok $now->get_epoch_milli;
ok !$now->is_zero;

my $added = $now->add_days(1);
isa_ok $added, 'UID2::Client::XS::Timestamp';
ok $added->get_epoch_second > $now->get_epoch_second;
ok $added->get_epoch_milli > $now->get_epoch_milli;

$added = $now->add_seconds(1);
isa_ok $added, 'UID2::Client::XS::Timestamp';
ok $added->get_epoch_second > $now->get_epoch_second;
ok $added->get_epoch_milli > $now->get_epoch_milli;

my $epoch = 1642775407;
my $from_epoch_second = UID2::Client::XS::Timestamp->from_epoch_second($epoch);
isa_ok $from_epoch_second, 'UID2::Client::XS::Timestamp';
is $from_epoch_second->get_epoch_second, $epoch;
is $from_epoch_second->get_epoch_milli, $epoch * 1000;

my $from_epoch_milli = UID2::Client::XS::Timestamp->from_epoch_milli($epoch * 1000);
isa_ok $from_epoch_milli, 'UID2::Client::XS::Timestamp';
is $from_epoch_milli->get_epoch_second, $epoch;
is $from_epoch_milli->get_epoch_milli, $epoch * 1000;

done_testing;
