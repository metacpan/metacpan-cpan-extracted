use strict;
use warnings;
use Test::More;
use Time::Moment;
use Role::Tiny ();

{package My::Fake::TimeZone;
  sub new { bless {} }
  sub offset_for_datetime { 0 }
  sub offset_for_local_datetime { 0 }
  sub is_dst_for_datetime { 0 }
}

my $tz = My::Fake::TimeZone->new;

my $class = Role::Tiny->create_class_with_roles('Time::Moment', 'Time::Moment::Role::TimeZone');
my $tm = $class->now_utc->with_offset(-5 * 60);

my $tm_si = $tm->with_time_zone_offset_same_instant($tz);
is $tm->epoch, $tm_si->epoch, 'same instant';
isnt $tm->strftime('%T'), $tm_si->strftime('%T'), 'different local time';
is $tm_si->offset, 0, 'right offset';
my $tm_sl = $tm->with_time_zone_offset_same_local($tz);
isnt $tm->epoch, $tm_sl->epoch, 'different instant';
is $tm->strftime('%T'), $tm_sl->strftime('%T'), 'same local time';
is $tm_sl->offset, 0, 'right offset';

$tm = Time::Moment->now_utc->with_offset(-5 * 60);
Role::Tiny->apply_roles_to_object($tm, 'Time::Moment::Role::TimeZone');

$tm_si = $tm->with_time_zone_offset_same_instant($tz);
is $tm->epoch, $tm_si->epoch, 'same instant';
isnt $tm->strftime('%T'), $tm_si->strftime('%T'), 'different local time';
is $tm_si->offset, 0, 'right offset';
$tm_sl = $tm->with_time_zone_offset_same_local($tz);
isnt $tm->epoch, $tm_sl->epoch, 'different instant';
is $tm->strftime('%T'), $tm_sl->strftime('%T'), 'same local time';
is $tm_sl->offset, 0, 'right offset';

done_testing;
