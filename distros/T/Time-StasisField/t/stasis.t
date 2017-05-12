#!/usr/bin/env perl

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib/";

use Time::StasisField (qw{:all});
use Test::More(tests => 51);

my $class = 'Time::StasisField';

sub test_alarm {
	do {
		my $is_triggered = 0;
		local $SIG{ALRM} = sub { $is_triggered = 1};
		alarm(3);
		$class->tick for 1 .. 5;
		is $is_triggered, 1, 'tick triggers a set alarm';
	};

	do {
		my $is_triggered = 0;
		local $SIG{ALRM} = sub { $is_triggered = 1};
		alarm(3);
		time for 1 .. 5;
		is $is_triggered, 1, 'time triggers a set alarm';
	};

	do {
		my $is_triggered = 0;
		local $SIG{ALRM} = sub { $is_triggered = 1};
		alarm(3);
		$class->now($class->now + 3);
		is $is_triggered, 1, 'setting now to the exact alarm time triggers a set alarm';
	};

	do {
		my $is_triggered = 0;
		local $SIG{ALRM} = sub { $is_triggered = 1};
		alarm(3);
		$class->now($class->now + 5);
		is $is_triggered, 1, 'setting now past the alarm time triggers a set alarm';
	};

	do {
		my $is_triggered = 0;
		local $SIG{ALRM} = sub { $is_triggered = 1};
		alarm(3);
		alarm(0);
		time for 1 .. 5;
		is $is_triggered, 0, 'setting alarm to zero unsets the alarm';
	};

	do {
		my $is_triggered = 0;
		local $SIG{ALRM} = sub { $is_triggered = 1};
		alarm(3);
		time for 1 .. 5;
		is alarm(0), 0, 'alarm returns zero if the previous alarm triggered';
	};

	is do { alarm(6000); alarm(0) }, 6000, 'alarm returns the time remaining on the previous alarm';
	is do { alarm(6000.01); alarm(0) }, 6000, 'alarm does not support subsecond times';
	is do { alarm(-1); alarm(0) }, undef, 'alarm treats prior negative alarms as undef';
}

sub test_frozen_time {
	my $now = $class->now;

	$class->freeze;
	is time, $now, 'time does not move while frozen';
	cmp_ok $class->tick, '>', $now, 'freezing time does not freeze tick';
	is $class->now(12345), 12345, 'freezing time does not affect setting now';
	sleep(2);
	is $class->now, 12347, 'freezing time does not affect sleep';
	$class->unfreeze;
	is time, 12348, 'time continues once unfrozen';
}

sub test_normal_time {
	cmp_ok time - CORE::time, '<=', 1, 'time starts with the same value as CORE::time';
	is time, $class->now, 'the time is now';
	is time + 1, time, 'time marches on';
	my $now = $class->now;
	time for 1 .. 10;
	is $class->now, $now + 10, 'time is predictable';
}

sub test_now {
	is $class->now, $class->now, 'now is now';
	is $class->now(12345), 12345, 'now is modifiable';
	is $class->now(12345.5), 12345, 'now returns integer time';
	is $class->now(-12345), -12345, 'now can be negative';
	is $class->now($class->now(42.25)), $class->now(42.25), 'now is idempotent';
	ok ! (eval { $class->now('bad') ;1 }), 'now only accepts numbers';
}

sub test_seconds_per_tick {
	my ($now, $tick_size);

	is $class->seconds_per_tick, 1, 'seconds_per_tick returns the tick size';

	for (
		[-3 => 'negative seconds'],
		[-0.25 => 'negative subseconds'],
		[0 => 'zero seconds'],
		[0.25 => 'positive subseconds'],
		[5 => 'positive seconds'],
	) {
		my ($tick_size, $label) = @$_;
		is $class->seconds_per_tick($tick_size), $tick_size, "seconds_per_tick supports $label";
		my $now = $class->now;
		is time, int($now + $tick_size), "time returns an integer when seconds_per_tick is set to $label";
		time for (1 .. 3);
		is $class->now, int($now + 4 * $tick_size), "seconds_per_tick moves time by the proper number of seconds given $label";
	}

	$class->seconds_per_tick(1);
}

sub test_sleep {
	for (
		[0 => 'zero seconds'],
		[0.25 => 'positive subseconds'],
		[5 => 'positive seconds'],
	) {
		my ($duration, $label) = @$_;
		my $now = $class->now;
		is sleep($duration), int($duration), "sleep returns the integer number of seconds passed given $label";
		is $class->now, int($now + $duration), "sleep advances time by the proper number of seconds given $label";
	}

	do {
		my $is_triggered = 0;
		local $SIG{ALRM} = sub { $is_triggered = 1};
		CORE::alarm(1);
		sleep(-2);
		is $is_triggered, 1, 'sleep pauses runtime indefinitely given a negative duration';
	};

	do {
		my $is_triggered = 0;
		local $SIG{ALRM} = sub { $is_triggered = 1};
		CORE::alarm(1);
		sleep;
		is $is_triggered, 1, 'sleep pauses runtime indefinitely when called without arguments';
	};

}

sub test_tick {
	my $now;
	is $class->tick, $class->now, 'tick returns now';
	$now = $class->now;
	cmp_ok $class->tick, '>', $now, 'tick advances time';
	$class->seconds_per_tick(5);
	$now = $class->now;
	is $class->tick, $now + 5, 'tick obeys seconds_per_tick';
	$class->seconds_per_tick(1);
}

for my $test (sort grep { $_ =~ /^test_/ } keys %{main::}) {
	do {
		local $\ = "\n";
		local $, = " ";
		print '#', split /_/, $test;
	};
	$class->engage;
	do { no strict 'refs'; &$test };
	$class->disengage;
}
