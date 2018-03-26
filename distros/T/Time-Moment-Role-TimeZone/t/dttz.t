use strict;
use warnings;
use Test::More;
use Time::Moment;
use Role::Tiny ();
use Test::Needs 'DateTime::TimeZone';

my $tz = DateTime::TimeZone->new(name => 'Asia/Pyongyang');
my $tm = Role::Tiny->create_class_with_roles('Time::Moment', 'Time::Moment::Role::TimeZone')
  ->new(year => 2018, month => 1, day => 1);

my $tm_si = $tm->with_time_zone_offset_same_instant($tz);
is $tm->epoch, $tm_si->epoch, 'same instant';
isnt $tm->strftime('%T'), $tm_si->strftime('%T'), 'different local time';
is $tm_si->offset * 60, $tz->offset_for_datetime($tm), 'right offset';
my $tm_sl = $tm->with_time_zone_offset_same_local($tz);
isnt $tm->epoch, $tm_sl->epoch, 'different instant';
is $tm->strftime('%T'), $tm_sl->strftime('%T'), 'same local time';
is $tm_sl->offset * 60, $tz->offset_for_local_datetime($tm), 'right offset';

done_testing;
