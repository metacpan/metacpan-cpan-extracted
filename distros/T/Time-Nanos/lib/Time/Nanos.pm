package Time::Nanos;

use strict;
use warnings;
use Exporter 'import';

use autouse 'Carp' => qw(croak);

our $VERSION = 'v0.1.6';
our @EXPORT  = qw(nanos micros millis);
our $CLOCK   = 0;

require XSLoader;
XSLoader::load('Time::Nanos', $VERSION);

sub nanos {
	my $as_array = shift();
	my $ns       = hrtime($Time::Nanos::CLOCK);

	if ($as_array) {
		my $sec  = int($ns / 1_000_000_000);
		my $nsec = $ns % 1_000_000_000;

		return ($sec, $nsec);
	}

	return $ns;
}

sub micros {
	my $as_array = shift();
	my $ns = hrtime($Time::Nanos::CLOCK);

	if ($as_array) {
		my $sec  = int($ns / 1_000_000_000);
		my $usec = int(($ns % 1_000_000_000) / 1000);

		return ($sec, $usec);
	}

	my $us = int($ns / 1000);
	return $us;
}

sub millis {
	my $as_array = shift();
	my $ns = hrtime($Time::Nanos::CLOCK);

	if ($as_array) {
		my $sec  = int($ns / 1_000_000_000);
		my $msec = int(($ns % 1_000_000_000) / 1_000_000);
		return ($sec, $msec);
	}

	my $ms = int($ns / 1_000_000);
	return $ms;
}

sub clock_source {
	my $input = shift();

	if (!defined $input) {
		croak("clock_source() requires an argument");
	} elsif ($input eq "realtime" || $input eq "0") {
		$CLOCK = 0;
	} elsif ($input eq "monotonic" || $input eq "1") {
		$CLOCK = 1;
	} else {
		croak("Unknown source '$input'");
	}
}

1;

__END__

=head1 NAME

Time::Nanos - Nanosecond time resolution via clock_gettime().

=head1 SYNOPSIS

    use Time::Nanos;

    my $nanoseconds  = nanos();
    my $microseconds = micros();
    my $milliseconds = millis();

    my ($seconds, $nanoseconds)  = nanos(1);
    my ($seconds, $microseconds) = micros(1);
    my ($seconds, $milliseconds) = millis(1);

=head1 FUNCTIONS

=head2 nanos()

    my $ns = nanos();
    my ($sec, $nsec) = nanos(1);

Returns the current time as an integer number of nanoseconds. With a true
argument, returns a list of (seconds, nanoseconds) instead.

=head2 micros()

    my $us = micros();
    my ($sec, $usec) = micros(1);

Returns the current time as an integer number of microseconds. With a true
argument, returns a list of (seconds, microseconds) instead.

=head2 millis()

    my $ms = millis();
    my ($sec, $msec) = millis(1);

Returns the current time as an integer number of milliseconds. With a true
argument, returns a list of (seconds, milliseconds) instead.

=head2 Time::Nanos::clock_source()

    Time::Nanos::clock_source('monotonic');

Selects which clock source the functions use. Defaults to C<'realtime'>.
Valid values: C<'realtime'> or C<'monotonic'>.
C<clock_source()> is not exported, so it must be called fully qualified.

=head1 DESCRIPTION

This module provides high-resolution time via C<clock_gettime()>.
The default clock is C<CLOCK_REALTIME>. C<'realtime'> uses the system clock,
which measures time since the Unix epoch. This is susceptible to clock skew from
NTP updates, user clock changes, etc.  When using C<'realtime'>, it is possible
(but rare) to observe a negative duration when comparing two successive calls.

When using C<'monotonic'> the clock reference epoch is unspecified, so a single
reading is not in itself a useful measurement of time. These values are only
meaningful when compared against each other to measure elapsed time.

On 32-bit Perl builds the nanosecond granularity is around 256 ns rather than
an exact value. The C<(seconds, fraction)> array forms remain usable.

=cut
