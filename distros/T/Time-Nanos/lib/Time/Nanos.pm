package Time::Nanos;

use strict;
use warnings;
use Exporter 'import';

our $VERSION = 'v0.1.4';
our @EXPORT  = qw(nanos micros millis);
our $CLOCK   = 'realtime';

require XSLoader;
XSLoader::load('Time::Nanos', $VERSION);

sub nanos { hrtime(@_) }

sub micros {
	my $ret_array = $_[0] // 0;

	if ($ret_array) {
		my ($sec, $nsec) = nanos(1);
		return ($sec, int($nsec / 1000));
	}

	return int(nanos() / 1000);
}

sub millis {
	my $ret_array = $_[0] // 0;

	if ($ret_array) {
		my ($sec, $nsec) = nanos(1);
		return ($sec, int($nsec / 1_000_000));
	}
	return int(nanos() / 1_000_000);
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

    my ($seconds, $nanoseconds) = nanos(1);

=head1 VARIABLES

=head2 $CLOCK

    $Time::Nanos::CLOCK = 'realtime';

Controls which clock source the functions use. Defaults to C<'realtime'>.
Valid values: C<'monotonic'> or C<'realtime'>.

=head1 FUNCTIONS

=head2 nanos()

    my $ns = nanos();
    my ($sec, $nsec) = nanos(1);

Returns nanoseconds. In scalar context returns total nanoseconds. With a true
argument returns a list of (seconds, nanoseconds) instead.

=head2 micros()

    my $us = micros();
    my ($sec, $usec) = micros(1);

Returns microseconds as an integer. In scalar context returns total
microseconds. With a true argument returns a list of (seconds, microseconds)
instead.

=head2 millis()

    my $ms = millis();
    my ($sec, $msec) = millis(1);

Returns milliseconds as an integer. In scalar context returns total
milliseconds. With a true argument returns a list of (seconds, milliseconds)
instead.

=head1 DESCRIPTION

This module provides high-resolution time via C<clock_gettime()>.
The default clock is C<CLOCK_REALTIME>. C<'realtime'> uses the system clock,
which measures time since the Unix epoch. This is susceptible to clock skew from
NTP updates, user clock changes, etc.  When using C<'realtime'>, it is possible
(but rare) to observe a negative duration when comparing two successive calls.

When using C<'monotonic'> the clock reference epoch is unspecified, so a single
reading is not in itself a useful measurement of time. These values are only
meaningful when compared against each other to measure elapsed time.

=cut
