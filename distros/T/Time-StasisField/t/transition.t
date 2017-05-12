#!/usr/bin/env perl

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib/";

use Time::StasisField (qw{:all});
use Test::More (tests => 21);

my $class = 'Time::StasisField';

local $SIG{ALRM} = sub { die ["TRIGGERED", $class->now] };

sub test_alarm_across_engage_disengage {
	my $now = $class->now;
	alarm(3);
	$class->engage;
	time for 1 .. 2;
	$class->disengage;
	ok eval { sleep(1); 1 };
	eval { sleep(4) };
	my $error = $@;

	is $error->[0], 'TRIGGERED';
	is $error->[1] - $now, 3;
}

sub test_alarm_only_triggers_once {
	my $now = $class->now;
	alarm(1);
	eval { sleep(1) };
	$class->engage;
	$class->now($now);
	ok eval { sleep(2); 1 };
}

sub test_disengage {
	$class->engage;

	ok $class->is_engaged;
	$class->disengage;
	my $now = $class->now;
	ok ! $class->is_engaged;
	alarm(2);
	CORE::sleep(1);
	$class->disengage;
	is alarm(0), 1;
	is $class->now, $now + 1;
	ok ! $class->is_engaged;
}

sub test_disengage_stasis_after_setting_alarm {
	$class->engage;
	my $now = $class->now;
	alarm(2);
	$class->disengage;
	eval { sleep(8) };
	my $error = $@;

	is $error->[0], 'TRIGGERED';
	is $error->[1] - $now, 2;
}

sub test_disengage_triggers_alarm_from_time_traveling {
	my $now = $class->now;
	$class->engage;
	$class->now($class->now - 20);
	alarm(3);
	eval { $class->disengage };
	my $error = $@;

	is $error->[0], 'TRIGGERED';
	is $error->[1] - $now, 0;
}

sub test_engage {
	ok ! $class->is_engaged;
	my $now = $class->now;
	$class->engage;
	ok $class->is_engaged;
	alarm(1);
	CORE::sleep(1);
	eval { $class->engage; 1 };
	my $error = $@;
	is $error->[0], 'TRIGGERED';
	is $class->now, $now + 1;
	ok $class->is_engaged;
}

sub test_engage_stasis_after_setting_alarm {
	my $now = $class->now;
	alarm(3);
	$class->engage;
	eval { time for 1 .. 20 };
	my $error = $@;

	is $error->[0], 'TRIGGERED';
	is $error->[1] - $now, 3;

	ok eval { $class->engage; CORE::sleep(3);1 };
}

for my $test (sort grep { $_ =~ /^test_/ } keys %{main::}) {
	do {
		local $\ = "\n";
		local $, = " ";
		print '#', split /_/, $test;
	};

	eval { no strict 'refs'; &$test; 1 }
		|| do { warn "FAILURE: $test exited early: $@" };

	CORE::alarm(0);
	alarm(0);
	$class->disengage;
}
