package Test::Mockingbird::TimeTravel;

use strict;
use warnings;

use Carp qw(croak);
use Time::Local qw(timegm);

use Exporter 'import';
our @EXPORT = qw(
	now
	freeze_time
	travel_to
	advance_time
	rewind_time
	restore_all
	with_frozen_time
);

# ----------------------------------------------------------------------
# Internal state
# ----------------------------------------------------------------------

our $ACTIVE		= 0;	  # whether time is frozen
our $CURRENT_EPOCH = undef;  # current simulated time
our $BASE_EPOCH	= undef;  # epoch at moment of freeze

=head1 NAME

Test::Mockingbird::TimeTravel - Deterministic, controllable time for Perl tests

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

    use Test::Mockingbird::TimeTravel qw(
        now
        freeze_time
        travel_to
        advance_time
        rewind_time
        restore_all
        with_frozen_time
    );

    # Freeze time at a known point
    freeze_time('2025-01-01T00:00:00Z');
    is now(), 1735689600, 'time is frozen';

    # Move the frozen clock forward
    advance_time(2 => 'minutes');
    is now(), 1735689720, 'time advanced deterministically';

    # Temporarily override time inside a block
    with_frozen_time '2025-01-02T12:00:00Z' => sub {
        is now(), 1735819200, 'block sees overridden time';
    };

    # After the block, the previous frozen time is restored
    is now(), 1735689720, 'outer time restored';

    # Return to real system time
    restore_all();
    isnt now(), 1735689720, 'real time restored';

=head1 DESCRIPTION

C<Test::Mockingbird::TimeTravel> provides a lightweight, deterministic
time-control layer for Perl tests. It allows you to freeze time, move it
forward or backward, jump to specific timestamps, and run code under a
temporary time override - all without touching Perl's built-in C<time()>
or relying on global monkey-patching.

The module is designed for test suites that need:

=over 4

=item *

predictable timestamps

=item *

repeatable behaviour across runs

=item *

clean separation between real time and simulated time

=item *

safe, nestable time overrides

=back

Unlike traditional mocking of C<time()>, TimeTravel does not replace Perl's core functions.
Instead, it provides a dedicated C<now()> function
and a small set of declarative operations that manipulate an internal,
frozen clock. This avoids global side effects and makes time behaviour
explicit in your tests.

=head2 Core Concepts

=over 4

=item * C<now()>

Returns the current simulated time if time is frozen, or the real system
time otherwise.

=item * C<freeze_time>

Freezes time at a specific timestamp. All subsequent calls to C<now()>
return the frozen value until time is restored.

=item * C<travel_to>

Moves the frozen clock to a new timestamp.

=item * C<advance_time> / C<rewind_time>

Moves the frozen clock forward or backward by a duration, expressed in
seconds, minutes, hours, or days.

=item * C<with_frozen_time>

Temporarily overrides time inside a code block, restoring the previous
state afterward - even if the block dies.

=item * C<restore_all>

Restores real time and clears all frozen state.

=back

TimeTravel is fully compatible with L<Test::Mockingbird::DeepMock>, which
can apply time-travel plans declaratively as part of a larger mocking scenario.

=head2 now

Return the current time according to the TimeTravel engine.

=head3 Purpose

C<now()> provides a deterministic replacement for Perl's built-in
C<time()> when writing tests. If time is frozen (via C<freeze_time>,
C<travel_to>, C<advance_time>, or C<rewind_time>), C<now()> returns the
simulated epoch value. If time is not frozen, it returns the real system
time.

This allows test suites to avoid nondeterministic behaviour caused by
wall-clock time, while still permitting explicit control over temporal
flow.

=head3 Arguments

None. C<now()> takes no parameters.

=head3 Returns

An integer epoch timestamp:

=over 4

=item *

the simulated time if TimeTravel is active

=item *

the real system time (C<CORE::time()>) if TimeTravel is inactive

=back

=head3 Side Effects

None. C<now()> does not modify internal state; it only reads the current
frozen or real time.

=head3 Notes

=over 4

=item *

C<now()> is intentionally separate from Perl's C<time()> to avoid global
monkey-patching.

=item *

C<now()> is safe to call inside nested C<with_frozen_time> blocks.

=item *

When writing modules intended for testing, prefer calling C<now()> over
C<time()> so that behaviour can be controlled deterministically.

=back

=head3 Example

    use Test::Mockingbird::TimeTravel qw(now freeze_time restore_all);

    freeze_time('2025-01-01T00:00:00Z');
    my $t1 = now();   # deterministic epoch

    advance_time(60);
    my $t2 = now();   # exactly 60 seconds later

    restore_all();
    my $t3 = now();   # real system time again

=head3 API

=head4 Input (Params::Validate::Strict)

    now()

Input schema:

    {
        params => [],
        named  => 0,
    }

=head4 Output (Returns::Set)

    returns: Int

Output schema:

    {
        returns => 'Int',   # epoch seconds
    }

=cut

sub now () {
	return $ACTIVE ? $CURRENT_EPOCH : CORE::time();
}

=head2 freeze_time

Freeze the TimeTravel clock at a specific timestamp.

=head3 Purpose

C<freeze_time()> activates the TimeTravel engine and sets the simulated
clock to a deterministic epoch value. Once frozen, all calls to C<now()>
return the frozen time until it is changed by C<travel_to>,
C<advance_time>, C<rewind_time>, or restored via C<restore_all>.

This is the primary entry point for deterministic time control in tests.

=head3 Arguments

    freeze_time($timestamp)

Takes a single required argument:

=over 4

=item * C<$timestamp> - a timestamp in any format supported by
C<_parse_timestamp>, including:

    YYYY-MM-DD
    YYYY-MM-DD HH:MM:SS
    YYYY-MM-DDTHH:MM:SSZ
    raw epoch seconds

=back

=head3 Returns

An integer epoch value representing the frozen time.

=head3 Side Effects

=over 4

=item * Activates the TimeTravel engine (sets C<$ACTIVE> to 1)

=item * Sets both C<$CURRENT_EPOCH> and C<$BASE_EPOCH> to the parsed
timestamp

=item * Causes all subsequent calls to C<now()> to return the frozen
epoch

=back

=head3 Notes

=over 4

=item * Calling C<freeze_time()> when time is already frozen simply
overwrites the current frozen value.

=item * The frozen time persists until explicitly changed or restored.

=item * Use C<restore_all()> to return to real system time.

=back

=head3 Example

    use Test::Mockingbird::TimeTravel qw(now freeze_time restore_all);

    my $t = freeze_time('2025-01-01T00:00:00Z');
    is $t, 1735689600, 'freeze_time returns epoch';

    is now(), 1735689600, 'now() returns frozen time';

    advance_time(120);
    is now(), 1735689720, 'time advanced deterministically';

    restore_all();
    isnt now(), 1735689720, 'real time restored';

=head3 API

=head4 Input (Params::Validate::Strict)

    freeze_time($timestamp)

Input schema:

    {
        params => [
            { type => 'Str | Int' },   # timestamp in any supported format
        ],
        named => 0,
    }

=head4 Output (Returns::Set)

    returns: Int

Output schema:

    {
        returns => 'Int',   # epoch seconds
    }

=cut

sub freeze_time {
	my ($ts) = @_;

	$CURRENT_EPOCH = _parse_timestamp($ts);
	$BASE_EPOCH	= $CURRENT_EPOCH;
	$ACTIVE		= 1;

	return $CURRENT_EPOCH;
}

=head2 travel_to

Move the frozen TimeTravel clock to a new timestamp.

=head3 Purpose

C<travel_to()> updates the simulated time to a specific timestamp while
keeping the TimeTravel engine active. It is used to jump directly to a
new moment without unfreezing time or altering the fact that time is
currently frozen.

This is useful for tests that need to simulate large jumps in time
instantly, such as expiring sessions, rotating logs, or advancing
scheduled events.

=head3 Arguments

    travel_to($timestamp)

Takes a single required argument:

=over 4

=item * C<$timestamp> - a timestamp in any format supported by
C<_parse_timestamp>, including:

    YYYY-MM-DD
    YYYY-MM-DD HH:MM:SS
    YYYY-MM-DDTHH:MM:SSZ
    raw epoch seconds

=back

=head3 Returns

An integer epoch value representing the new simulated time.

=head3 Side Effects

=over 4

=item * Croaks if called while TimeTravel is inactive.

=item * Updates C<$CURRENT_EPOCH> to the parsed timestamp.

=item * Leaves C<$ACTIVE> set to 1 (time remains frozen).

=item * Does not modify C<$BASE_EPOCH>; only C<freeze_time()> sets the
base.

=back

=head3 Notes

=over 4

=item * C<travel_to()> cannot be used unless time has already been
frozen.

=item * To temporarily override time inside a block, use
C<with_frozen_time()> instead.

=item * C<travel_to()> is deterministic and does not depend on real
system time.

=back

=head3 Example

    use Test::Mockingbird::TimeTravel qw(
        now freeze_time travel_to restore_all
    );

    freeze_time('2025-01-01T00:00:00Z');
    is now(), 1735689600, 'initial freeze';

    travel_to('2025-01-03T12:34:56Z');
    is now(), 1735907696, 'jumped to new timestamp';

    restore_all();
    isnt now(), 1735907696, 'real time restored';

=head3 API

=head4 Input (Params::Validate::Strict)

    travel_to($timestamp)

Input schema:

    {
        params => [
            { type => 'Str | Int' },   # timestamp in any supported format
        ],
        named => 0,
    }

=head4 Output (Returns::Set)

    returns: Int

Output schema:

    {
        returns => 'Int',   # epoch seconds
    }

=cut

sub travel_to {
	croak "travel_to() called while TimeTravel is inactive"
		unless $ACTIVE;

	$CURRENT_EPOCH = _parse_timestamp($_[0]);
	return $CURRENT_EPOCH;
}

=head2 advance_time

Advance the frozen TimeTravel clock by a specified duration.

=head3 Purpose

C<advance_time()> moves the simulated clock forward by a given amount of
time. It is used to model the passage of time in a deterministic way
while the TimeTravel engine is active. This is especially useful for
testing expiry windows, retry backoff, cache TTLs, and any logic that
depends on elapsed time.

=head3 Arguments

    advance_time($amount, $unit)

Takes two arguments:

=over 4

=item * C<$amount> - a positive or negative integer representing the
magnitude of the time shift

=item * C<$unit> - an optional unit string. Supported units:

    second
    seconds
    minute
    minutes
    hour
    hours
    day
    days

If no unit is provided, the amount is interpreted as raw seconds.

=back

=head3 Returns

An integer epoch value representing the new simulated time after the
advance.

=head3 Side Effects

=over 4

=item * Croaks if called while TimeTravel is inactive.

=item * Converts the amount and unit into seconds.

=item * Adds the computed delta to C<$CURRENT_EPOCH>.

=item * Leaves C<$ACTIVE> set to 1 (time remains frozen).

=back

=head3 Notes

=over 4

=item * C<advance_time()> does not modify C<$BASE_EPOCH>; only
C<freeze_time()> sets the base.

=item * Negative amounts are allowed but uncommon; use C<rewind_time()>
for clarity.

=item * The operation is deterministic and independent of real system
time.

=back

=head3 Example

    use Test::Mockingbird::TimeTravel qw(
        now freeze_time advance_time restore_all
    );

    freeze_time('2025-01-01T00:00:00Z');
    is now(), 1735689600, 'initial freeze';

    advance_time(30);
    is now(), 1735689630, 'advanced 30 seconds';

    advance_time(2 => 'minutes');
    is now(), 1735689750, 'advanced 2 minutes';

    restore_all();
    isnt now(), 1735689750, 'real time restored';

=head3 API

=head4 Input (Params::Validate::Strict)

    advance_time($amount, $unit)

Input schema:

    {
        params => [
            { type => 'Int' },          # amount
            { type => 'Str', optional => 1 },   # unit
        ],
        named => 0,
    }

=head4 Output (Returns::Set)

    returns: Int

Output schema:

    {
        returns => 'Int',   # epoch seconds
    }

=cut

sub advance_time {
	croak 'advance_time() called while TimeTravel is inactive' unless $ACTIVE;

	my ($amount, $unit) = @_;
	my $delta = _unit_to_seconds($amount, $unit);

	$CURRENT_EPOCH += $delta;
	return $CURRENT_EPOCH;
}

=head2 rewind_time

Rewind the frozen TimeTravel clock by a specified duration.

=head3 Purpose

C<rewind_time()> moves the simulated clock backward by a given amount of
time. It is the inverse of C<advance_time()> and is used to test logic
that depends on earlier timestamps, negative offsets, or rollback
scenarios, all in a deterministic and controlled way.

=head3 Arguments

    rewind_time($amount, $unit)

Takes two arguments:

=over 4

=item * C<$amount> - a positive or negative integer representing the
magnitude of the time shift

=item * C<$unit> - an optional unit string. Supported units:

    second
    seconds
    minute
    minutes
    hour
    hours
    day
    days

If no unit is provided, the amount is interpreted as raw seconds.

=back

=head3 Returns

An integer epoch value representing the new simulated time after the
rewind.

=head3 Side Effects

=over 4

=item * Croaks if called while TimeTravel is inactive.

=item * Converts the amount and unit into seconds.

=item * Subtracts the computed delta from C<$CURRENT_EPOCH>.

=item * Leaves C<$ACTIVE> set to 1 (time remains frozen).

=back

=head3 Notes

=over 4

=item * C<rewind_time()> does not modify C<$BASE_EPOCH>; only
C<freeze_time()> sets the base.

=item * Negative amounts are allowed but uncommon; use C<advance_time()>
for clarity when moving forward.

=item * The operation is deterministic and independent of real system
time.

=back

=head3 Example

    use Test::Mockingbird::TimeTravel qw(
        now freeze_time rewind_time restore_all
    );

    freeze_time('2025-01-01T00:00:00Z');
    is now(), 1735689600, 'initial freeze';

    rewind_time(30);
    is now(), 1735689570, 'rewound 30 seconds';

    rewind_time(1 => 'hour');
    is now(), 1735685970, 'rewound 1 hour';

    restore_all();
    isnt now(), 1735685970, 'real time restored';

=head3 API

=head4 Input (Params::Validate::Strict)

    rewind_time($amount, $unit)

Input schema:

    {
        params => [
            { type => 'Int' },          # amount
            { type => 'Str', optional => 1 },   # unit
        ],
        named => 0,
    }

=head4 Output (Returns::Set)

    returns: Int

Output schema:

    {
        returns => 'Int',   # epoch seconds
    }

=cut

sub rewind_time {
	croak 'rewind_time() called while TimeTravel is inactive' unless $ACTIVE;

	my ($amount, $unit) = @_;
	my $delta = _unit_to_seconds($amount, $unit);

	$CURRENT_EPOCH -= $delta;
	return $CURRENT_EPOCH;
}

=head2 restore_all

Restore real time and clear all TimeTravel state.

=head3 Purpose

C<restore_all()> deactivates the TimeTravel engine and returns the system
to normal, non-frozen time.
After calling this function, C<now()> once
again returns the real system time from C<CORE::time()>.

This is the canonical way to end a time-travel scenario in tests.

=head3 Arguments

None. C<restore_all()> takes no parameters.

=head3 Returns

Nothing. The function returns an undefined value.

=head3 Side Effects

=over 4

=item * Sets C<$ACTIVE> to 0, disabling frozen time.

=item * Clears C<$CURRENT_EPOCH>.

=item * Clears C<$BASE_EPOCH>.

=item * Causes all subsequent calls to C<now()> to return real system
time.

=back

=head3 Notes

=over 4

=item * C<restore_all()> is idempotent; calling it multiple times is
safe.

=item * It is automatically invoked by L<Test::Mockingbird::DeepMock>
when a time plan is used.

=item * Use this function at the end of tests to ensure no frozen state
leaks into later tests.

=back

=head3 Example

    use Test::Mockingbird::TimeTravel qw(
        now freeze_time advance_time restore_all
    );

    freeze_time('2025-01-01T00:00:00Z');
    advance_time(60);
    is now(), 1735689660, 'time is frozen and advanced';

    restore_all();
    isnt now(), 1735689660, 'real time restored';

=head3 API

=head4 Input (Params::Validate::Strict)

    restore_all()

Input schema:

    {
        params => [],
        named  => 0,
    }

=head4 Output (Returns::Set)

    returns: Undef

Output schema:

    {
        returns => 'Undef',
    }

=cut

sub restore_all {
	$ACTIVE		= 0;
	$CURRENT_EPOCH = undef;
	$BASE_EPOCH	= undef;
}

=head2 with_frozen_time

Temporarily override the TimeTravel clock inside a code block.

=head3 Purpose

C<with_frozen_time()> runs a block of code under a temporary frozen
timestamp, restoring the previous time state afterward. This allows tests
to simulate nested or scoped time overrides without permanently altering
the global TimeTravel state.

It is the safest way to test code that depends on time within a limited
scope, especially when combined with C<freeze_time()>, C<travel_to()>,
C<advance_time()>, or C<rewind_time()>.

=head3 Arguments

    with_frozen_time($timestamp, $code)

Takes two required arguments:

=over 4

=item * C<$timestamp> - a timestamp in any format supported by
C<_parse_timestamp>, including:

    YYYY-MM-DD
    YYYY-MM-DD HH:MM:SS
    YYYY-MM-DDTHH:MM:SSZ
    raw epoch seconds

=item * C<$code> - a coderef to execute while the override is active

=back

=head3 Returns

Returns whatever the code block returns. In list context, returns a list.
In scalar context, returns the block's scalar result. In void context,
returns nothing.

=head3 Side Effects

=over 4

=item * Saves the current TimeTravel state (active flag, current epoch,
base epoch).

=item * Activates frozen time using the provided timestamp.

=item * Executes the code block under the overridden time.

=item * Restores the previous TimeTravel state after the block completes,
even if the block throws an exception.

=item * Rethrows any exception from inside the block.

=back

=head3 Notes

=over 4

=item * C<with_frozen_time()> is fully nestable; each invocation restores
its own state.

=item * It does not require time to be frozen beforehand.

=item * It is ideal for testing code that performs multiple time-based
operations in different scopes.

=back

=head3 Example

    use Test::Mockingbird::TimeTravel qw(
        now freeze_time with_frozen_time restore_all
    );

    freeze_time('2025-01-01T00:00:00Z');
    my $outer = now();   # 1735689600

    my $inner;
    with_frozen_time '2025-01-02T00:00:00Z' => sub {
        $inner = now();  # 1735776000
    };

    is $inner, 1735776000, 'inner block saw overridden time';
    is now(), $outer, 'outer frozen time restored';

    restore_all();

=head3 API

=head4 Input (Params::Validate::Strict)

    with_frozen_time($timestamp, $code)

Input schema:

    {
        params => [
            { type => 'Str | Int' },   # timestamp
            { type => 'CodeRef' },     # block to execute
        ],
        named => 0,
    }

=head4 Output (Returns::Set)

    returns: Any

Output schema:

    {
        returns => 'Any',   # whatever the block returns
    }

=cut

sub with_frozen_time {
	my ($ts, $code) = @_;

	croak "with_frozen_time() requires a coderef"
		unless ref($code) eq 'CODE';

	croak "with_frozen_time() requires a timestamp"
		unless defined $ts;

	my $prev_active = $ACTIVE;
	my $prev_epoch  = $CURRENT_EPOCH;
	my $prev_base   = $BASE_EPOCH;

	$CURRENT_EPOCH = _parse_timestamp($ts);
	$BASE_EPOCH	= $CURRENT_EPOCH;
	$ACTIVE		= 1;

	my @ret;
	my $err;

	{
		local $@;
		@ret = eval { $code->() };
		$err = $@;
	}

	$ACTIVE		= $prev_active;
	$CURRENT_EPOCH = $prev_epoch;
	$BASE_EPOCH	= $prev_base;

	die $err if $err;

	return wantarray ? @ret : $ret[0];
}

# ----------------------------------------------------------------------
# NAME
#     _parse_timestamp
#
# PURPOSE
#     Convert a timestamp string into an epoch value. Supports raw epoch
#     integers, ISO8601 UTC (YYYY-MM-DDTHH:MM:SSZ), space-separated
#     timestamps (YYYY-MM-DD HH:MM:SS), and date-only formats
#     (YYYY-MM-DD, interpreted as midnight UTC).
#
# ENTRY CRITERIA
#     - $ts: a defined, non-empty scalar containing a timestamp in one
#       of the supported formats.
#
# EXIT STATUS
#     - Returns an integer epoch value corresponding to the parsed
#       timestamp.
#     - Croaks if the input is undefined, empty, or not in a supported
#       format.
#
# SIDE EFFECTS
#     - None. This routine does not modify global or package state.
#
# NOTES
#     - Leading and trailing whitespace is trimmed before parsing.
#     - Raw epoch values are returned unchanged.
#     - All parsed timestamps are interpreted as UTC.
# ----------------------------------------------------------------------
sub _parse_timestamp {
	my $ts = $_[0];

	croak 'Invalid timestamp format for TimeTravel: (undef)' unless defined $ts && length $ts;

	# Trim whitespace
	$ts =~ s/^\s+|\s+$//g;

	# Raw epoch
	return $ts if $ts =~ /^\d+$/;

	# ISO8601 UTC: YYYY-MM-DDTHH:MM:SSZ
	if ($ts =~ /^(\d{4})-(\d{2})-(\d{2})T
				 (\d{2}):(\d{2}):(\d{2})
				 Z$/x) {
		return timegm($6,$5,$4,$3,$2-1,$1);
	}

	# Space-separated timestamp: YYYY-MM-DD HH:MM:SS
	if ($ts =~ /^(\d{4})-(\d{2})-(\d{2})\s+
				 (\d{2}):(\d{2}):(\d{2})$/x) {
		return timegm($6,$5,$4,$3,$2-1,$1);
	}

	# Date-only: YYYY-MM-DD → midnight UTC
	if ($ts =~ /^(\d{4})-(\d{2})-(\d{2})$/) {
		return timegm(0,0,0,$3,$2-1,$1);
	}

	croak "Invalid timestamp format for TimeTravel: $ts";
}

# Backwards compatibility for tests
sub _parse_datetime { _parse_timestamp(@_) }

# ----------------------------------------------------------------------
# NAME
#     _unit_to_seconds
#
# PURPOSE
#     Convert a numeric amount and an optional time unit into a number
#     of seconds. Supports seconds, minutes, hours, and days. Used by
#     advance_time() and rewind_time() to normalize time deltas.
#
# ENTRY CRITERIA
#     - $amount: integer magnitude of the time shift.
#     - $unit: optional string naming the unit. If omitted, $amount is
#       treated as raw seconds. Supported units:
#           second, seconds
#           minute, minutes
#           hour, hours
#           day, days
#
# EXIT STATUS
#     - Returns an integer number of seconds.
#     - Croaks if an unknown unit is provided.
#
# SIDE EFFECTS
#     - None. Does not modify global or package state.
#
# NOTES
#     - Unit matching is case-insensitive.
#     - Negative amounts are allowed and simply produce negative deltas.
# ----------------------------------------------------------------------
sub _unit_to_seconds {
	my ($amount, $unit) = @_;

	# No unit → raw seconds
	return $amount unless defined $unit;

	$unit = lc $unit;

	my %factor = (
		second  => 1,
		seconds => 1,
		minute  => 60,
		minutes => 60,
		hour	=> 3600,
		hours   => 3600,
		day	 => 86400,
		days	=> 86400,
	);

	croak "Unknown time unit '$unit'" unless exists $factor{$unit};

	return $amount * $factor{$unit};
}

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-test-mockingbird at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Mockingbird>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Test::Mockingbird::TimeTravel

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

=head1 SEE ALSO

=over 4

=item * L<Test::Mockingbird>

=item * L<Test::Mockingbird::DeepMock>

=back

=head1 REPOSITORY

L<https://github.com/nigelhorne/Test-Mockingbird>

=head1 SUPPORT

This module is provided as-is without any warranty.

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
