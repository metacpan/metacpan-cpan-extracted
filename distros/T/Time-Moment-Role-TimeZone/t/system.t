use strict;
use warnings;
use Test::More;
use Time::Moment;
use Role::Tiny ();

my $class = Role::Tiny->create_class_with_roles('Time::Moment', 'Time::Moment::Role::TimeZone');
my $tm = $class->now_utc->with_offset(Time::Moment->now->offset + 3 * 60);

my $tm_si = $tm->with_system_offset_same_instant;
is $tm->epoch, $tm_si->epoch, 'same instant';
isnt $tm->strftime('%T'), $tm_si->strftime('%T'), 'different local time';
my $tm_sl = $tm->with_system_offset_same_local;
isnt $tm->epoch, $tm_sl->epoch, 'different instant';
is $tm->strftime('%T'), $tm_sl->strftime('%T'), 'same local time';

done_testing;
