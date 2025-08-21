use 5.010;
use strict;
use warnings;

package Time::Left;
our $VERSION = '1.000';

use Exporter qw(import);
use Scalar::Util qw(looks_like_number);
use Time::HiRes qw(clock_gettime);

use constant CLOCK =>
    eval { Time::HiRes::CLOCK_MONOTONIC_RAW() } //
    eval { Time::HiRes::CLOCK_MONOTONIC() } //
    Time::HiRes::CLOCK_REALTIME();

use overload
    bool     => 'active',
    '!'      => 'expired',
    '0+'     => '_numify',
    '<=>'    => '_compare',
    '""'     => '_stringify',
    cmp      => '_strcmp',
    nomethod => '_nomethod',
    ;

our @EXPORT_OK = qw(to_seconds time_left);

sub _die { exists(&Carp::croak) ? goto &Carp::croak : die "@_\n" }

### Functions

sub to_seconds {
    my ($t) = @_;
    unless (looks_like_number($t)) {
        return undef
            unless $t =~ /^(.+)([smhd])$/
            and looks_like_number($1);
        $t = $1;
        if    ($2 eq 'm') { $t *= 60    }
        elsif ($2 eq 'h') { $t *= 3600  }
        elsif ($2 eq 'd') { $t *= 86400 }
    }
    return $t;
}

sub time_left {
    my ($t) = @_;
    return defined($t) ?
        Time::Left->new(to_seconds($t) // _die("time_left: invalid duration '$_[0]'")) :
        Time::Left->new($t);
}

### Methods

sub new {
    my ($class, $time) = @_;
    _die("${class}->new: invalid time '$time'")
        unless looks_like_number($time // 0);
    $time += clock_gettime(CLOCK)
        if defined $time;
    return bless(\$time, ref($class)||$class);
}

sub remaining  { defined(${$_[0]}) ? ${$_[0]} -  clock_gettime(CLOCK) : undef }
sub active     { defined(${$_[0]}) ? ${$_[0]} >  clock_gettime(CLOCK) : 1     }
sub expired    { defined(${$_[0]}) ? ${$_[0]} <= clock_gettime(CLOCK) : !1    }
sub is_limited { defined(${$_[0]}) }
sub abort      { ${$_[0]} = clock_gettime(CLOCK) }

sub _numify    { _die("Can't numify Time::Left") }
sub _nomethod  { _die("Time::Left does not overload '$_[3]'") }
sub _stringify { defined(${$_[0]}) ? sprintf("%.3f", $_[0]->remaining) : 'Inf' }
sub _strcmp    { ($_[0]->_stringify cmp (ref($_[1]) ? $_[1]->_stringify : $_[1])) * ($_[2] ? -1 : 1) }
sub _compare {
    my ($a, $b, $swap) = @_;
    $a = $$a // 'Inf';
    $b = ref($b) ? $$b // 'Inf' : defined($b) ? $b + clock_gettime(CLOCK) : 'Inf';
    return $swap ? $b <=> $a : $a <=> $b;
}

1;
__END__

=head1 NAME

Time::Left - Object model for time limits

=head1 SYNOPSIS

    use Time::Left qw(to_seconds time_left);
    # Function interface
    $sec = to_seconds($duration);
    $timer = time_left($duration);
    # Object interface
    $timer = Time::Left->new($sec);
    $sec_left = $timer->remaining; # also num/str overload
    $bool = $timer->active;        # also boolean overload
    $bool = $timer->expired;       # also boolean overload
    $bool = $timer->is_limited;
    $timer->abort;

=head1 DESCRIPTION

This module provides a simple object for managing time limits and a
simple duration string parser function.  It does not generate signals
on its own, but is well-suited to providing values to timers or a
timeout for select().

Objects can be created via time_left() or the new() method.

    $timer = time_left("1m");     # permits unit-qualified strings
    $timer = Time::Left->new(60); # requires number in seconds

The number of seconds remaining is obtained via remaining().

    $sec_left = $timer->remaining;

The $sec_left value becomes negative when the timer has expired.  If
the initial value to new() or time_left() is negative, then the timer
is already expired when created.  There is also an "expired" method
which becomes true at zero or less.

    $bool = $timer->expired;

A timer initialised with undef is an "indefinite" timer.  These always
return undef for the remaining time, which is semantically appropriate
for a select() timeout.  You can test whether a timer object is
limited or indefinite via the is_limited() method.

    $bool = $timer->is_limited;

=head1 FUNCTIONS

The following functions can be imported.

=head2 to_seconds

    $sec = to_seconds($duration);

Converts $duration to a number of seconds.  The duration can be either
a plain number, in which case it is passed through as is, or a number
with a suffix of "s" (seconds), "m" (minutes), "h" (hours), or "d"
(days); e.g. "2.5m" is 150 seconds.  Returns undef if $duration is
invalid.  Negative values are permitted.

=head2 time_left

    $timer = time_left($duration);

Returns a new B<Time::Left> object.  If $duration is undef, the limit
is indefinite; if C<< to_seconds($duration) >> returns a number, the
limit is that many seconds; otherwise $duration is invalid and an
exception is raised.

=head1 METHODS

The object interface is as follows.

=head2 new

    $timer = Time::Left->new($sec);

Creates an object with the specified time left in seconds, or an
indefinite timer if $sec is undef.  Dies/croaks if $sec is defined but
not numeric.

=head2 remaining

    $sec_left = $timer->remaining;

Returns the seconds left on the timer, or undef for indefinite timers.
This is semantically correct for use as a timeout in select(), but you
will need to guard against undef if treating this as a number.  See
L</OVERLOADING> for related possibilities.

=head2 active

Returns true if the time remaining is greater than zero.  Always true
for indefinite timers.  This is available as a boolean overload: see
L</OVERLOADING>.

=head2 expired

Returns true if the time remaining is zero or less.  Always false for
indefinite timers.  This is available as the negation overload: see
L</OVERLOADING>.

=head2 is_limited

Returns false for indefinite timers, true otherwise.

=head2 abort

Sets the timer to expire right now.  An indefinite timer ceases to be
so when aborted, since it just had a limit imposed on it.

=head1 OVERLOADING

The object has boolean, string, and limited numeric overloading.  An
exception will occur if unsupported overloading is attempted.  No
mutating operators are supported.

=head2 boolean

Uses the "active" method.  Negation uses the "expired" method.

=head2 string

Returns remaining time rendered to millisecond precision, or "Inf" for
indefinite timers.  String comparison is supported but not special.

=head2 numeric

Numeric overloading is intended to represent the remaining time, but
is limited by the desire to be compatible with the select() function
timeout.  This must be undef for indefinite timers, but overloading
numification to return undef doesn't work in this context, nor does
returning 'Inf'.  As such, B<numeric context is generally forbidden>
and will raise an exception.

B<Numeric comparison operators are supported>, however: you can
meaningfully compare remaining time on two timers (even indefinite
ones) or against a number of seconds.

=head1 EXAMPLES

In the following examples, $timer is a B<Time::Left> object, limited
or indefinite, set up at some earlier point.

=head2 Time-limited read on a non-blocking socket, ignoring EINTR

    my $sel = IO::Select->new($sock);
    while ($timer->active) {
        $! = 0;
        $sel->can_read($timer->remaining);
        next if $!{EINTR};
        last if $!;
        $sock->recv($buffer, $n);
        last unless $!{EINTR};
    }

=head2 Set up an AnyEvent timer unless indefinite

    my $t = AnyEvent->timer(after => $timer->remaining, cb => $code)
        if $timer->is_limited;

=head2 Countdown using overloading

    my $t = time_left(10);
    while ($t) { print "$t\n"; sleep(1) }

=head1 NOTE

Timing is performed via clock_gettime() in L<Time::HiRes>.  The most
preferred clock is CLOCK_MONOTONIC_RAW, which is not affected by time
changes or frequency adjustments.  CLOCK_MONOTONIC is the second
preference: it is affected by frequency adjustments.  Last preference
is CLOCK_REALTIME, which is expected to be available everywhere, but
can misbehave if the clock is changed.

Exceptions are thrown with L<Carp> croak() if present, die() if not.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Brett Watson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
