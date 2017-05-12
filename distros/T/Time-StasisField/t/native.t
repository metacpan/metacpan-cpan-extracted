#!/usr/bin/env perl

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib/";

use Time::StasisField;
use Test::More(tests => 21);

my $seed_time = CORE::time;
#Time advances steadily when stasis is engaged, so let's rule that out
Time::StasisField->engage;
time for 0 .. 10;
Time::StasisField->disengage;

cmp_ok time - $seed_time, '<=', 1, 'time returns the same value as CORE::time';

ok join('', reverse CORE::gmtime) <= join('', reverse gmtime)
&& join('', reverse CORE::gmtime) >= join('', reverse gmtime),
	'gmtime returns the same value as CORE::gmtime with no argument';

is
	scalar gmtime($seed_time),
	scalar CORE::gmtime($seed_time),
	'gmtime returns the same value as CORE::gmtime in scalar context';

is
	join("\x1F", gmtime($seed_time)),
	join("\x1F", CORE::gmtime($seed_time)),
	'gmtime returns the same value as CORE::gmtime in list context';

ok join('', reverse CORE::localtime) <= join('', reverse localtime)
&& join('', reverse CORE::localtime) >= join('', reverse localtime),
	'localtime returns the same value as CORE::localtime with no argument';

is
	scalar localtime($seed_time),
	scalar CORE::localtime($seed_time),
	'localtime returns the same value as CORE::localtime in scalar context';

is
	join("\x1F", localtime($seed_time)),
	join("\x1F", CORE::localtime($seed_time)),
	'localtime returns the same value as CORE::localtime in list context';

is CORE::sleep(2), sleep(2), 'sleep returns the same value as CORE::sleep';
cmp_ok time + 1 - do {sleep(0);    time}, '<=', 1, 'sleep does not pause runtime given a zero duration';
cmp_ok time + 1 - do {sleep(0.01); time}, '<=', 1, 'sleep does not pause runtime given a subsecond duration';
cmp_ok time + 3 - do {sleep(2);    time}, '<=', 1, 'sleep pauses runtime for the correct amount given a nontrivial sleep time';

is alarm(6000), 0, 'alarm initially returns 0 seconds';
is do { alarm(6000); alarm(0) }, 6000, 'alarm returns the time remaining on the previous alarm';
is do { alarm(6000.01); alarm(0) }, 6000, 'alarm does not support subsecond times';
is do { alarm(-1); alarm(0) }, undef, 'alarm treats prior negative alarms as undef';

do {
	my $is_triggered = 0;
	local $SIG{ALRM} = sub { $is_triggered = 1};
	my $time_before_alarm = time;
	alarm(2);
	sleep(5);
	cmp_ok time - ($time_before_alarm + 2), '<=', 1, 'alarm triggers after appropriate number of seconds';
	is $is_triggered, 1, 'alarm triggers sigalarm';
	is alarm(0), 0, 'alarm returns zero if the previous alarm triggered';
};

do {
	my $is_triggered = 0;
	local $SIG{ALRM} = sub { $is_triggered = 1};
	alarm(1);
	alarm(0);
	sleep(2);
	is $is_triggered, 0, 'alarm is disabled when set to zero';
};

do {
	my $is_triggered = 0;
	local $SIG{ALRM} = sub { $is_triggered = 1};
	alarm(1);
	sleep;
	is $is_triggered, 1, 'sleep pauses runtime indefinitely without a duration';
};

do {
	my $is_triggered = 0;
	local $SIG{ALRM} = sub { $is_triggered = 1};
	alarm(1);
	sleep(-2);
	is $is_triggered, 1, 'sleep pauses runtime indefinitely given a negative duration';
};
