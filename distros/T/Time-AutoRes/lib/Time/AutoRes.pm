package Time::AutoRes;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $use_hires);

$VERSION = 0.02;

@ISA = qw(Exporter);
require Exporter;

BEGIN {
    eval 'require Time::HiRes';
    $use_hires = not $@;
    if ($use_hires) {
        @EXPORT    = @Time::HiRes::EXPORT;
        @EXPORT_OK = @Time::HiRes::EXPORT_OK;
    } else {
        @EXPORT    = qw();
        @EXPORT_OK = qw(sleep alarm usleep ualarm time);
    }
}

sub import {
    if ($use_hires) {
        Time::HiRes->export_to_level(0, @Time::HiRes::EXPORT_OK);
        Time::HiRes->export_to_level(1, @_);
    } else {
        eval <<'EOS';
sub Time::AutoRes::sleep {
    my ($delta) = @_;
    my $int_delta = int $delta;
    $int_delta++ if rand() < $delta - $int_delta;
    CORE::sleep $int_delta if $int_delta;
}

sub Time::AutoRes::alarm {
    my ($delta) = @_;
    my $int_delta = int $delta;
    $int_delta++ if rand() < $delta - $int_delta;
    CORE::alarm $int_delta;
}

sub Time::AutoRes::usleep {
    Time::AutoRes::sleep($_[0] / 1_000_000);
}

sub Time::AutoRes::ualarm {
    Time::AutoRes::alarm($_[0] / 1_000_000);
}

sub Time::AutoRes::time {
    CORE::time
}
EOS
        __PACKAGE__->export_to_level(1, @_);
    }
}


1;


=head1 NAME

Time::AutoRes - use Time::HiRes or fall back to core code

=head1 SYNOPSIS

    use Time::AutoRes qw(sleep time alarm);
    sleep(1.5);
    $now = time;
    alarm($now + 2.5);

=head1 DESCRIPTION

Time::AutoRes provides access to most of the functions that may be
imported from Time::HiRes (see list below).  If Time::HiRes isn't
available, Time::AutoRes silently falls back to core Perl functions;
when this happens, it tries to emulate Time::HiRes by rounding
non-integers up or down in such a way as to approximate the
non-integer value B<on average> over repeated calls.

For example, if you call C<usleep(3.4)>, B<and if Time::HiRes is not
available>, there's a 40% chance of sleeping for 4 seconds, and a 60%
chance of sleeping for only 3 seconds.  If you call C<usleep(3.4)>
repeatedly, the average delay will tend toward 3.4 seconds.


=head1 EXPORTABLE FUNCTIONS

=over 4

=item sleep($interval_in_seconds)

Sleep the given number of sleeps.  If the interval is not an integer,
B<and Time::HiRes is not available>, Time::AutoRes will randomize the
delay as described above so that repeated calls with the same interval
can be expected to sleep the specified interval B<on average>.

=item usleep($interval_in_microseconds)

Seleep the given number of microseconds.  There are one million
microseconds in a second.  Randomness is used when Time::HiRes is not
available and a non-integer argument is given, in exactly the same way
as for Time::AutoRes::sleep.

=item alarm($interval_in_seconds)

Arranges to have a SIGALRM delivered to this process after the
specified number of seconds have elapsed.  Randomness is used when
appropriate, as for Time::AutoRes::sleep.

=item ualarm($interval_in_microseconds)

Same as C<alarm> but in microseconds rather than seconds.  Again,
randomness is used when appropriate.

=item time()

Returns the number of non-leap seconds since the epoch.

This simply calls Time::HiRes::time if it's available, or CORE::Time
if not.

B<Note:> This is the only exported function that never uses
randomness!

=back

=head1 BUGS

gettimeofday(), tv_interval(), getitimer() and setitimer() aren't
implemented.

=head1 AUTHOR

Paul Hofman (nkuitse AT cpan DOT org).

=head1 COPYRIGHT

Copyright 2004 Paul M. Hoffman.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

