#!/usr/bin/env perl
use strict;
use warnings;
use Time::Nanos;
use v5.16;

my $st = stopwatch(1);

#print "Using Time::Nanos " . $Time::Nanos::VERSION . "\n\n";
printf("Using %s %s\n\n", color('white', 'Time::Nanos'), color(228, $Time::Nanos::VERSION));

for (1 .. 4) {
	my $ns = nanos();
	printf "Time (monotonic): %s nanoseconds\n", $ns;
}

print "\n";

for (1 .. 4) {
	my ($sec, $nsec) = nanos(1);
	printf "Time (monotonic): %d.%09d seconds\n", $sec, $nsec;
}

print "\n";

for (1 .. 4) {
	my $ns = nanos(0, 'realtime');
	printf "Time (realtime): %s nanoseconds\n", $ns;
}

print "\n";

for (1 .. 4) {
	my ($sec, $nsec) = nanos(1, 'realtime');
	printf "Time (realtime): %d.%09d seconds\n", $sec, $nsec;
}

print "\n";

for (1 .. 4) {
	my $us = micros();
	printf "Time (monotonic): %s microseconds\n", $us;
}

print "\n";

for (1 .. 4) {
	my $ms = millis();
	printf "Time (monotonic): %s milliseconds\n", $ms;
}

my $total = stopwatch();
print "\n";
printf("Script executed in %d ns\n", $total);

################################################################################
################################################################################

# String format: '115', '165_bold', '10_on_140', 'reset', 'on_173', 'red', 'white_on_blue'
sub color {
	my ($str, $txt) = @_;

	if (-t STDOUT == 0 || $ENV{NO_COLOR}) { return $txt // ""; } # No interactive terminal
	if (!length($str) || $str eq 'reset') { return "\e[0m";    } # No string = RESET

	# Some predefined colors/commands
	my %color_map = qw(red 160 blue 27 green 34 yellow 226 orange 214 purple 93 white 15 black 0);
	my %cmd_map   = qw(bold 1 italic 3 underline 4 blink 5 inverse 7);

	# Pre-process the string.
	$str =~ s/on_/-/;                              # "on_" becomes a negative number
	$str =~ s|([A-Za-z]+)|$color_map{$1} // $1|eg; # command number

	my @parts = split("_", $str);
	foreach my $p (@parts) {
		my $cmd_num = $cmd_map{$p // 0};

		if    ($cmd_num)                      { $p = $cmd_num;  }
		elsif (defined($p) && $p =~ /^-(.+)/) { $p = "48;5;$p"; }
		elsif (defined($p))                   { $p = "38;5;$p"; }
	}

	my $ret = "\e[" . join(";", @parts) . "m";

	if (defined($txt)) { $ret .= $txt . "\e[0m"; }

	return $ret;
}

# Stopwatch(1) = start
# Stopwatch()  = return ns from start time
sub stopwatch {
	my $start         = shift();
	state $last_start = undef;
	my $ret;

	if ($start) {
		$last_start = nanos();
		$ret        = $last_start;
	} else {
		$ret = nanos() - $last_start;
	}

	return $ret;
}
