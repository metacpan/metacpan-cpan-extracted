use strict;
use warnings;

package Try::ALRM;

# ABSTRACT: Structured retry and timeout handling using CORE::alarm

our $VERSION = q{1.03};

use Exporter qw/import/;
use Scalar::Util qw/refaddr/;
use Time::HiRes qw/time/;

our @EXPORT    = qw(try_once retry ALRM finally timeout tries);
our @EXPORT_OK = qw(try_once retry ALRM finally timeout tries);

our $TIMEOUT = 60;
our $TRIES   = 3;

my @ALARM_STACK;

sub timeout (;$) {
    my $timeout = shift;
    if ( defined $timeout ) {
        _assert_timeout($timeout);
        $TIMEOUT = $timeout;
    }
    return $TIMEOUT;
}

sub tries (;$) {
    my $tries = shift;
    if ( defined $tries ) {
        _assert_tries($tries);
        $TRIES = $tries;
    }
    return $TRIES;
}

sub try_once (&;@) {
    my $block = shift;
    &retry( $block, @_, tries => 1 );    # bypass prototype intentionally
}

sub retry (&;@) {
    my $block = shift;

    my $spec = _parse_retry_args(@_);

    my $retry_block   = $block;
    my $alarm_block   = $spec->{ALRM};
    my $finally_block = $spec->{finally} || sub { };

    my $timeout = exists $spec->{timeout} ? $spec->{timeout} : $TIMEOUT;
    my $tries   = exists $spec->{tries}   ? $spec->{tries}   : $TRIES;

    _assert_timeout($timeout);
    _assert_tries($tries);

    local $TIMEOUT = $timeout;
    local $TRIES   = $tries;

    my $attempts  = 0;
    my $succeeded = 0;
    my $error;

    ATTEMPT:
    for my $attempt ( 1 .. $tries ) {
        $attempts = $attempt;

        my $alarm_token = bless \( my $token = "Try::ALRM timeout" ),
            'Try::ALRM::_Timeout';

        local $SIG{ALRM} = \&_dispatch_alarm;

        my $frame = _push_alarm_frame(
            timeout => $timeout,
            attempt => $attempt,
            handler => $alarm_block,
            token   => $alarm_token,
        );

        my $ok = eval {
            $retry_block->($attempt);
            _pop_alarm_frame($frame);
            1;
        };

        my $eval_error = $@;

        _pop_alarm_frame($frame);

        if ($ok) {
            $succeeded = 1;
            last ATTEMPT;
        }

        if (
            ref($eval_error)
            && ref($eval_error) eq 'Try::ALRM::_Timeout'
            && refaddr($eval_error) == refaddr($alarm_token)
        ) {
            next ATTEMPT;
        }

        $error = $eval_error || 'Unknown error';
        last ATTEMPT;
    }

    my $finally_error;
    eval {
        $finally_block->( $attempts, $succeeded );
        1;
    } or do {
        $finally_error = $@ || 'Unknown error';
    };

    die $error         if defined $error;
    die $finally_error if defined $finally_error;

    return;
}

sub ALRM (&;@) {
    return ALRM => @_;
}

sub finally (&;@) {
    return finally => @_;
}

sub _push_alarm_frame {
    my %frame = @_;

    $frame{deadline} = time() + $frame{timeout};

    push @ALARM_STACK, \%frame;
    _reset_alarm();

    return \%frame;
}

sub _pop_alarm_frame {
    my $frame = shift;

    return unless $frame;

    @ALARM_STACK = grep {
        refaddr($_) != refaddr($frame)
    } @ALARM_STACK;

    _reset_alarm();

    return;
}

sub _dispatch_alarm {
    my $now = time();

    my @expired = sort {
        $a->{deadline} <=> $b->{deadline}
    } grep {
        $_->{deadline} <= $now
    } @ALARM_STACK;

    unless (@expired) {
        _reset_alarm();
        return;
    }

    my $frame = $expired[0];

    if ( ref( $frame->{handler} ) eq 'CODE' ) {
        $frame->{handler}->( $frame->{attempt} );
    }

    die $frame->{token};
}

sub _reset_alarm {
    CORE::alarm(0);

    return unless @ALARM_STACK;

    my ($next) = sort {
        $a->{deadline} <=> $b->{deadline}
    } @ALARM_STACK;

    my $remaining = $next->{deadline} - time();

    if ( $remaining <= 0 ) {
        CORE::alarm(1);
        return;
    }

    CORE::alarm( _ceil($remaining) );

    return;
}

sub _ceil {
    my $value = shift;

    return int($value) == $value ? int($value) : int($value) + 1;
}

sub _parse_retry_args {
    my @args = @_;

    die "Odd number of arguments to retry\n" if @args % 2;

    my %spec;

    while (@args) {
        my ( $key, $value ) = splice @args, 0, 2;

        die "Unknown retry argument '$key'\n"
            unless $key eq 'ALRM'
                || $key eq 'finally'
                || $key eq 'timeout'
                || $key eq 'tries';

        die "Duplicate retry argument '$key'\n"
            if exists $spec{$key};

        if ( $key eq 'ALRM' || $key eq 'finally' ) {
            die "$key must be a CODE reference\n"
                unless ref($value) eq 'CODE';
        }

        $spec{$key} = $value;
    }

    return \%spec;
}

sub _assert_timeout {
    my $timeout = shift;

    die qq{timeout must be an integer >= 1!\n}
        unless defined $timeout
            && $timeout =~ /\A[1-9][0-9]*\z/;
}

sub _assert_tries {
    my $tries = shift;

    die qq{tries must be an integer >= 1!\n}
        unless defined $tries
            && $tries =~ /\A[1-9][0-9]*\z/;
}

__PACKAGE__;

__END__

=head1 NAME

Try::ALRM - Structured retry and timeout handling using CORE::alarm

=head1 DESCRIPTION

C<Try::ALRM> provides try/catch-like semantics around C<alarm>.

Internally, this module uses Perl prototypes to coerce lexical blocks
into C<CODE> references, in the same spirit as L<Try::Tiny>. The public
syntax remains compact:

    retry { ... }
    ALRM  { ... }
    finally { ... }
    timeout => 5,
    tries   => 10;

Timeouts are handled by a localized C<$SIG{ALRM}> handler. When the
alarm fires, the optional C<ALRM> block is executed and the current
attempt is immediately aborted. If retry attempts remain, C<retry>
continues with the next attempt.

The active alarm is always cleared before control leaves the attempt,
whether the block succeeds, times out, or dies for another reason.

C<retry> and C<try_once> may be nested. Active timeout scopes are tracked
internally so an inner timeout does not permanently cancel an outer one.

C<retry> and C<try_once> may be nested. Timeout scopes are tracked so
that inner timeouts do not cancel outer ones. When multiple timeouts are
active, the earliest deadline wins.

=head1 EXPORTS

This module exports six keywords.

=head2 try_once BLOCK

Runs BLOCK once with an alarm set to the current timeout value.

C<try_once> is equivalent to:

    retry { ... } tries => 1;

If an alarm fires, the optional C<ALRM> block is executed, followed by
C<finally> if provided.

=head2 retry BLOCK

Runs BLOCK up to C<tries> times. Each attempt receives the current
attempt number via C<@_>.

Retries stop when either:

=over 4

=item *

The block completes without an alarm

=item *

The retry limit is reached

=item *

The block dies for a non-timeout reason

=back

If BLOCK dies for a non-timeout reason, C<finally> is still executed
before the original exception is rethrown.

Nested C<retry> and C<try_once> blocks operate independently. An inner
timeout only affects its own scope, while outer timeouts remain active.
If an outer timeout expires during an inner block, it is propagated
through the inner scope.


=head2 ALRM BLOCK

Optional handler executed when an alarm fires.

Receives the current attempt number:

    ALRM {
      my ($attempt) = @_;
      warn "Attempt $attempt timed out\n";
    }

After C<ALRM> runs, the current attempt is aborted and C<retry> moves to
the next attempt if one remains.

=head2 finally BLOCK

Optional block executed unconditionally after all attempts are complete,
or after a non-timeout exception interrupts retry processing.

Receives:

    my ($attempts, $successful) = @_;

C<$attempts> is the number of attempts actually made.

C<$successful> is true if one attempt completed without timing out or
throwing an exception.

If both the main block and C<finally> die, the main block's exception is
preserved and rethrown.

=head2 timeout INT

Getter/setter for the default timeout in seconds.

May also be supplied as a trailing modifier:

    try_once { ... } timeout => 2;

The value must be an integer greater than or equal to 1.

=head2 tries INT

Getter/setter for the default retry limit.

May also be supplied as a trailing modifier:

    retry { ... } tries => 5;

The value must be an integer greater than or equal to 1.

=head1 PACKAGE ENVIRONMENT

The following package variables are exposed:

=over 4

=item *

C<$Try::ALRM::TIMEOUT>

=item *

C<$Try::ALRM::TRIES>

=back

They may be set globally through the C<timeout> and C<tries> setters.

During a C<retry> or C<try_once> block, trailing C<timeout> and C<tries>
modifiers are localized so calls to C<timeout> and C<tries> inside user
blocks reflect the active values.

=head1 TRAILING MODIFIERS

Trailing modifiers are written as key/value pairs after the final block:

    retry {
      ...
    }
    ALRM {
      ...
    }
    finally {
      ...
    }
    timeout => 5,
    tries   => 10;

Valid trailing keys are:

=over 4

=item *

C<ALRM>

=item *

C<finally>

=item *

C<timeout>

=item *

C<tries>

=back

Unknown keys, duplicate keys, invalid timeout values, and invalid retry
counts are rejected.

=head1 COMPOSABILITY

C<Try::ALRM> supports nested usage of C<retry> and C<try_once>. Each block
maintains its own timeout context, allowing helper functions and inner
operations to define their own time limits without interfering with
outer control flow.

When multiple timeouts are active, the soonest deadline is enforced.

=head1 BUGS

Almost certainly.

This module was motivated both by curiosity about Perl prototypes and
by the practical question of whether C<ALRM> could be treated as a
localized exception.

Mileage may vary. Please report issues.

=head1 PERL ADVENT 2022

  | \__ `\O/  `--  {}    \}    {/    {}    \}    {/    {}    \} 
  \    \_(~)/_..___/=____/=____/=____/=____/=____/=____/=____/=*
   \=======/    //\\  >\/> || \>  //\\  >\/> || \>  //\\  >\/> 
  ----`---`---  `` `` ```` `` ``  `` `` ```` `` ``  ````  ````

=head1 ACKNOWLEDGEMENTS

"I<This module is dedicated to the least of you amongst us, the defenseless
unborn, and to all of those who have died suddenly.>"

=head1 AUTHOR

Brett Estrade (OODLER) L<< <oodler@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022-Present by Brett Estrade

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
