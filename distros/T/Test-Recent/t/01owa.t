#!/usr/bin/env perl

use strict;

use Test::More tests => 34;
use Test::Recent qw(occured_within_ago);

ok(defined &occured_within_ago, "exported");

# now is not now
my $now = DateTime->new(
	year => '2012',
	month => '05',
	day => '23',
	hour => '10',
	minute => '36',
	second => '30',
	time_zone => 'Z',
);

# manually set the clock
$Test::Recent::OverridedNowForTesting =  $now;

my $ten = DateTime::Duration->new( seconds => 10 );
ok occured_within_ago($now, $ten), "DateTime now";
ok !occured_within_ago($now + DateTime::Duration->new( seconds => 1), $ten), "future";
ok occured_within_ago($now + DateTime::Duration->new( seconds => -1), $ten), "past";
ok !occured_within_ago($now + DateTime::Duration->new( seconds => -11), $ten), "too past";

ok occured_within_ago('2012-05-23T10:36:30Z', "10s"), "now";
ok !occured_within_ago('2012-05-23T10:36:31Z', "10s"), "future";
ok occured_within_ago('2012-05-23T10:36:29Z', "10s"), "past";
ok !occured_within_ago('2012-05-23T10:36:19Z', "10s"), "too past";

# test bad cases
ok !occured_within_ago("This is utter junk", $ten), "DateTime junk";
ok !occured_within_ago(undef, $ten), "DateTime undef";

# test timezones
ok occured_within_ago('2012-05-23T11:36:30+01:00', "10s"), "now";
ok !occured_within_ago('2012-05-23T11:36:31+01:00', "10s"), "future";
ok occured_within_ago('2012-05-23T11:36:29+01:00', "10s"), "past";
ok !occured_within_ago('2012-05-23T11:36:19+01:00', "10s"), "too past";
ok occured_within_ago('2012-05-23T06:36:30-04', "10s"), "now";
ok !occured_within_ago('2012-05-23T06:36:31-04', "10s"), "future";
ok occured_within_ago('2012-05-23T06:36:29-04', "10s"), "past";
ok !occured_within_ago('2012-05-23T06:36:19-04', "10s"), "too past";

# test postgres style timezones
ok occured_within_ago('2012-05-23 06:36:29.987215-04','10s'), "postgres";

# test epoch seconds
ok occured_within_ago(1337769390, '10s'), "epoch";
ok occured_within_ago(1337769380, '10s'), "epoch 10s ago";

# test we cope with something that has nanoseconds
ok occured_within_ago('2012-05-23T10:36:30.987215','10s'), "nanoseconds (low)";
ok occured_within_ago('2012-05-23T10:36:30.187215','10s'), "nanoseconds (high)";

# test ecoch seconds with nanonseconds
ok occured_within_ago(1337769390.1234, '10s'), "epoch nanoseconds";
ok occured_within_ago(1337769390.988, '10s'), "epoch nanoseconds";

# test future handling
my $soon = $now + DateTime::Duration->new( seconds => 2 );
ok occured_within_ago($soon, [10, 2]) ,"future: epoch";
ok occured_within_ago($soon, [10, DateTime::Duration->new( seconds => 2 )]) ,"future: duration";
ok !occured_within_ago($soon, [10, 1]) ,"future: epoch fail";
ok !occured_within_ago($soon, [10, DateTime::Duration->new( seconds => 1 )]) ,"future: duration fail";

{
  local $Test::Recent::future_duration = 2;
  ok occured_within_ago($soon, 10), "future global: epoch";
}
{
  local $Test::Recent::future_duration = 1;
  ok !occured_within_ago($soon, 10), "future global: epoch fail";
}

{
  local $Test::Recent::future_duration = DateTime::Duration->new( seconds => 2 );
  ok occured_within_ago($soon, 10), "future global: duration";
}

{
  local $Test::Recent::future_duration = 1;
  ok !occured_within_ago($soon, 10), "future global: epoch fail";
}

