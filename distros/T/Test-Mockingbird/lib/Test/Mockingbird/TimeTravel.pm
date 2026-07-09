package Test::Mockingbird::TimeTravel;

use strict;
use warnings;

use Carp       qw(croak);
use Time::Local qw(timegm);
use Exporter   'import';

our @EXPORT = qw(
	now
	freeze_time
	travel_to
	advance_time
	rewind_time
	restore_all
	with_frozen_time
);

# Unit-to-seconds conversion table.  Singular and plural forms accepted;
# matching is case-insensitive (normalised in _unit_to_seconds).
my %SECONDS_PER_UNIT = (
	second  => 1,
	seconds => 1,
	minute  => 60,
	minutes => 60,
	hour    => 3600,
	hours   => 3600,
	day     => 86400,
	days    => 86400,
);

# Internal state -- three package variables so that with_frozen_time()
# can save/restore them with 'local'.
our $ACTIVE        = 0;      # 1 when frozen, 0 when using real time
our $CURRENT_EPOCH = undef;  # simulated time when frozen
our $BASE_EPOCH    = undef;  # epoch at the moment of freeze()

=head1 NAME

Test::Mockingbird::TimeTravel - Deterministic, controllable time for Perl tests

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

    use Test::Mockingbird::TimeTravel qw(
        now freeze_time travel_to advance_time rewind_time
        restore_all with_frozen_time
    );

    freeze_time('2025-01-01T00:00:00Z');
    is now(), 1735689600, 'time is frozen';

    advance_time(2 => 'minutes');
    is now(), 1735689720, 'time advanced deterministically';

    with_frozen_time '2025-01-02T12:00:00Z' => sub {
        is now(), 1735819200, 'block sees overridden time';
    };

    is now(), 1735689720, 'outer time restored after block';

    restore_all();
    isnt now(), 1735689720, 'real time restored';

=head1 DESCRIPTION

C<Test::Mockingbird::TimeTravel> provides a lightweight, deterministic
time-control layer for Perl tests. It does B<not> monkey-patch
C<CORE::time()>. Instead it provides a dedicated C<now()> function and a
small set of declarative operations that manipulate an internal frozen clock.

=head1 LIMITATIONS

=over 4

=item C<now()> is not a drop-in for C<time()>

Production code must call C<now()> for time control to take effect. Code
that calls C<CORE::time()>, C<POSIX::time()>, or C<Time::HiRes::time()>
directly is not affected.

=item Fractional seconds not supported

All timestamps are integer epoch seconds. Sub-second resolution is not
available.

=item Thread safety

C<$ACTIVE>, C<$CURRENT_EPOCH>, and C<$BASE_EPOCH> are package globals.
Concurrent threads that manipulate time state will race.

=back

=head1 METHODS

=head2 now

Return the current time.

Returns C<$CURRENT_EPOCH> when frozen, C<CORE::time()> otherwise.

=head3 API SPECIFICATION

=head4 Input (Params::Validate::Strict schema)

    none

=head4 Output (Returns::Set schema)

    returns: Int  -- epoch seconds

=head3 FORMAL SPECIFICATION

    now ≙ ($ACTIVE = 1 ⇒ returns $CURRENT_EPOCH) ∧ ($ACTIVE = 0 ⇒ returns CORE::time())

=cut

sub now () {
	return $ACTIVE ? $CURRENT_EPOCH : CORE::time();
}

=head2 freeze_time

Freeze the clock at a specific timestamp.

    my $epoch = freeze_time('2025-01-01T00:00:00Z');

=head3 API SPECIFICATION

=head4 Input (Params::Validate::Strict schema)

    $timestamp -- Str|Int (see _parse_timestamp for accepted formats)

=head4 Output (Returns::Set schema)

    returns: Int  -- frozen epoch

=head3 MESSAGES

  "Invalid timestamp format for TimeTravel: ..." -- unrecognised format

=head3 FORMAL SPECIFICATION

    freeze_time ≙
      ∀ ts : Str|Int •
        post $ACTIVE' = 1 ∧ $CURRENT_EPOCH' = parse(ts) ∧ $BASE_EPOCH' = parse(ts)

=cut

sub freeze_time {
	my ($ts) = @_;
	$CURRENT_EPOCH = _parse_timestamp($ts);
	$BASE_EPOCH    = $CURRENT_EPOCH;
	$ACTIVE        = 1;
	return $CURRENT_EPOCH;
}

=head2 travel_to

Move the frozen clock to a new timestamp without unfreezing.

    travel_to('2025-06-01T00:00:00Z');

Croaks if called while TimeTravel is inactive.

=head3 API SPECIFICATION

=head4 Input (Params::Validate::Strict schema)

    $timestamp -- Str|Int

=head4 Output (Returns::Set schema)

    returns: Int  -- new epoch

=head3 MESSAGES

  "travel_to() called while TimeTravel is inactive" -- freeze_time() not called first

=head3 FORMAL SPECIFICATION

    travel_to ≙
      pre  $ACTIVE = 1
      post $CURRENT_EPOCH' = parse(ts) ∧ $BASE_EPOCH unchanged ∧ $ACTIVE unchanged

=cut

sub travel_to {
	croak 'travel_to() called while TimeTravel is inactive' unless $ACTIVE;
	$CURRENT_EPOCH = _parse_timestamp($_[0]);
	return $CURRENT_EPOCH;
}

=head2 advance_time

Advance the frozen clock by a duration.

    advance_time(30);              # 30 seconds
    advance_time(2 => 'minutes');  # 2 minutes

Croaks if called while TimeTravel is inactive.

=head3 API SPECIFICATION

=head4 Input (Params::Validate::Strict schema)

    $amount -- Int
    $unit   -- Str, optional (second|minute|hour|day, plural forms ok)

=head4 Output (Returns::Set schema)

    returns: Int  -- new epoch

=head3 MESSAGES

  "advance_time() called while TimeTravel is inactive" -- not frozen
  "Unknown time unit '...'"                            -- unrecognised unit string

=head3 FORMAL SPECIFICATION

    advance_time ≙
      pre  $ACTIVE = 1
      post $CURRENT_EPOCH' = $CURRENT_EPOCH + to_seconds(amount, unit)

=cut

sub advance_time {
	croak 'advance_time() called while TimeTravel is inactive' unless $ACTIVE;
	my ($amount, $unit) = @_;
	$CURRENT_EPOCH += _unit_to_seconds($amount, $unit);
	return $CURRENT_EPOCH;
}

=head2 rewind_time

Rewind the frozen clock by a duration.

    rewind_time(30);           # 30 seconds
    rewind_time(1 => 'hour');  # 1 hour

Croaks if called while TimeTravel is inactive.

=head3 API SPECIFICATION

=head4 Input (Params::Validate::Strict schema)

    $amount -- Int
    $unit   -- Str, optional

=head4 Output (Returns::Set schema)

    returns: Int  -- new epoch

=head3 MESSAGES

  "rewind_time() called while TimeTravel is inactive" -- not frozen

=head3 FORMAL SPECIFICATION

    rewind_time ≙
      pre  $ACTIVE = 1
      post $CURRENT_EPOCH' = $CURRENT_EPOCH - to_seconds(amount, unit)

=cut

sub rewind_time {
	croak 'rewind_time() called while TimeTravel is inactive' unless $ACTIVE;
	my ($amount, $unit) = @_;
	$CURRENT_EPOCH -= _unit_to_seconds($amount, $unit);
	return $CURRENT_EPOCH;
}

=head2 restore_all

Return to real time and clear all frozen state.

    restore_all();

Idempotent. Called automatically by L<Test::Mockingbird::DeepMock>.

=head3 API SPECIFICATION

=head4 Input (Params::Validate::Strict schema)

    none

=head4 Output (Returns::Set schema)

    returns: undef

=head3 FORMAL SPECIFICATION

    restore_all ≙
      post $ACTIVE' = 0 ∧ $CURRENT_EPOCH' = undef ∧ $BASE_EPOCH' = undef

=cut

sub restore_all {
	$ACTIVE        = 0;
	$CURRENT_EPOCH = undef;
	$BASE_EPOCH    = undef;
	return;
}

=head2 with_frozen_time

Temporarily override time inside a code block, restoring previous state
afterward even if the block throws.

    with_frozen_time '2025-01-02T12:00:00Z' => sub {
        is now(), 1735819200, 'block sees overridden time';
    };

Fully nestable.

=head3 API SPECIFICATION

=head4 Input (Params::Validate::Strict schema)

    $timestamp -- Str|Int
    $code      -- CodeRef

=head4 Output (Returns::Set schema)

    returns: Any  -- whatever $code returns

=head3 MESSAGES

  "with_frozen_time() requires a coderef"    -- second arg not a CodeRef
  "with_frozen_time() requires a timestamp"  -- first arg undefined

=head3 FORMAL SPECIFICATION

    with_frozen_time ≙
      ∀ ts : Str|Int; code : CodeRef •
        pre  defined(ts) ∧ ref(code) = 'CODE'
        post (save prev_state; freeze(ts); run code; restore prev_state)
             ∧ exceptions rethrown

=cut

sub with_frozen_time {
	my ($ts, $code) = @_;

	croak 'with_frozen_time() requires a coderef'
		unless ref($code) eq 'CODE';

	croak 'with_frozen_time() requires a timestamp'
		unless defined $ts;

	# Save state so nested calls restore correctly
	my ($prev_active, $prev_epoch, $prev_base) =
		($ACTIVE, $CURRENT_EPOCH, $BASE_EPOCH);

	$CURRENT_EPOCH = _parse_timestamp($ts);
	$BASE_EPOCH    = $CURRENT_EPOCH;
	$ACTIVE        = 1;

	my (@ret, $err);
	{
		local $@;
		@ret = eval { $code->() };
		$err = $@;
	}

	$ACTIVE        = $prev_active;
	$CURRENT_EPOCH = $prev_epoch;
	$BASE_EPOCH    = $prev_base;

	# Re-throw as croak to stay consistent with the rest of this module
	croak $err if $err;

	return wantarray ? @ret : $ret[0];
}

# _parse_timestamp -- Private
#
# Purpose:      Convert a timestamp string to an integer epoch value.
#               Supports: raw epoch integer, ISO8601 UTC (YYYY-MM-DDTHH:MM:SSZ),
#               space-separated (YYYY-MM-DD HH:MM:SS), date-only (YYYY-MM-DD).
# Entry:        $_[0] -- Str, non-empty timestamp
# Exit:         Int, epoch seconds
# Side effects: none
sub _parse_timestamp {
	my $ts = $_[0];

	croak 'Invalid timestamp format for TimeTravel: (undef)'
		unless defined $ts && length $ts;

	$ts =~ s/^\s+|\s+$//g;   # trim whitespace

	# Raw epoch integer -- return unchanged
	return $ts if $ts =~ /^\d+$/;

	# ISO8601 UTC: YYYY-MM-DDTHH:MM:SSZ
	if ($ts =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z$/) {
		return timegm($6, $5, $4, $3, $2 - 1, $1);
	}

	# Space-separated: YYYY-MM-DD HH:MM:SS
	if ($ts =~ /^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})$/) {
		return timegm($6, $5, $4, $3, $2 - 1, $1);
	}

	# Date-only: YYYY-MM-DD interpreted as midnight UTC
	if ($ts =~ /^(\d{4})-(\d{2})-(\d{2})$/) {
		return timegm(0, 0, 0, $3, $2 - 1, $1);
	}

	croak "Invalid timestamp format for TimeTravel: $ts";
}

# Backwards-compatible alias used in some older tests.
sub _parse_datetime { _parse_timestamp(@_) }

# _unit_to_seconds -- Private
#
# Purpose:      Convert (amount, unit) into a number of seconds.
#               Unit is optional (raw seconds assumed if absent).
# Entry:        $amount -- Int; $unit -- Str or undef
# Exit:         Int, seconds
# Side effects: none
sub _unit_to_seconds {
	my ($amount, $unit) = @_;

	return $amount unless defined $unit;

	my $key = lc $unit;
	croak "Unknown time unit '$unit'"
		unless exists $SECONDS_PER_UNIT{$key};

	return $amount * $SECONDS_PER_UNIT{$key};
}

=head1 SUPPORT

Please report bugs at L<https://github.com/nigelhorne/Test-Mockingbird/issues>.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 SEE ALSO

=over 4

=item * L<Test::Mockingbird>

=item * L<Test::Mockingbird::DeepMock>

=back

=head1 REPOSITORY

L<https://github.com/nigelhorne/Test-Mockingbird>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to GPL2 licence terms.

=cut

1;
