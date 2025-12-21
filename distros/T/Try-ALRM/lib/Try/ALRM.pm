use strict;
use warnings;

package Try::ALRM;

our $VERSION = q{1.00};

use Exporter qw/import/;
our @EXPORT    = qw(try_once retry ALRM finally timeout tries);
our @EXPORT_OK = qw(try_once retry ALRM finally timeout tries);

our $TIMEOUT = 60;
our $TRIES   = 3;

# setter/getter for $Try::ALRM::TIMEOUT
sub timeout (;$) {
    my $timeout = shift;
    if ( defined $timeout ) {
        _assert_timeout($timeout);
        $TIMEOUT = $timeout;
    }
    return $TIMEOUT;
}

# setter/getter for $Try::ALRM::TRIES
sub tries (;$) {
    my $tries = shift;
    if ( defined $tries ) {
        _assert_tries($tries);
        $TRIES = $tries;
    }
    return $TRIES;
}

#NOTE: C<try_once> a case of C<retry>, where C<< tries => 1 >>.
sub try_once (&;@) {
    &retry( @_, tries => 1 );    #&retry, bypasses prototype
}

sub retry(&;@) {
    unshift @_, q{retry};        # adding marker, will be key for this &
    my %TODO = @_;
    my $TODO = \%TODO;

    my $RETRY   = $TODO->{retry}   // sub { };       # defaults to no-op
    my $ALRM    = $TODO->{ALRM}    // $SIG{ALRM};    # local ALRM defaults to global $SIG{ALRM}
    my $timeout = $TODO->{timeout} // $TIMEOUT;
    my $tries   = $TODO->{tries}   // $TRIES;
    my $FINALLY = $TODO->{finally} // sub { };

    local $TIMEOUT = $timeout;                       # make available to timeout(;$)
    local $TRIES   = $tries;                         # make available to tries(;$)

    my ( $attempts, $succeeded );

  TIMED_ATTEMPTS:
    for my $attempt ( 1 .. $TRIES ) {
        $attempts = $attempt;
        my $retry = 0;

        # NOTE: handler always becomes a local wrapper
        local $SIG{ALRM} = sub {
            ++$retry;
            if ( ref($ALRM) =~ m/^CODE$|::/ ) {
                $ALRM->($attempt);
            }
        };

        # actual alarm code
        alarm($timeout);
        $RETRY->($attempt);
        alarm 0;
        unless ( $retry == 1 ) {
            ++$succeeded;
            last;
        }
    }

    # "finally" (defaults to no-op 'sub {}' if block is not defined)
    $FINALLY->( $attempts, $succeeded );
}

sub ALRM (&;@) {
    unshift @_, q{ALRM};
    return @_;
}

sub finally (&;@) {
    unshift @_, q{finally};    # create marker, will be key for &
    return @_;
}

# internal method, validation
sub _assert_timeout {
    my $timeout = shift;
    if ( int $timeout <= 0 ) {
        die qq{timeout must be an integer >= 1!\n};
    }
}

# internal method, validation
sub _assert_tries {
    my $timeout = shift;
    if ( int $timeout <= 0 ) {
        die qq{timeout must be an integer >= 1!\n};
    }
}

__PACKAGE__

__END__

=encoding UTF-8

=head1 NAME

Try::ALRM - Try/catch-style semantics for handling timeouts using CORE::alarm

=head1 SYNOPSIS

C<Try::ALRM> provides a structured, readable way to use C<alarm> and
C<$SIG{ALRM}> without scattering signal handlers, local variables, and
cleanup logic throughout your code.

The primary entry point is C<retry>, which retries a block multiple times
when an alarm fires:

    use Try::ALRM;

    retry {
      my ($attempts) = @_;
      printf "Attempt %d/%d...\n", $attempts, tries;
      sleep 5;
    }
    ALRM {
      my ($attempts) = @_;
      print "\tTIMED OUT";
      if ($attempts < tries) {
        print " - retrying...\n";
      } else {
        print " - giving up...\n";
      }
    }
    finally {
      my ($attempts, $successful) = @_;
      my $limit   = tries;
      my $timeout = timeout;

      if ($successful) {
        print "Succeeded after $attempts attempts\n";
      } else {
        print "Failed after $limit attempts\n";
      }
    }
    timeout => 3,
    tries   => 4;

=head2 Single-attempt usage

C<try_once> is a reduced form of C<retry> equivalent to C<< tries => 1 >>.
It exists because “retry” can read awkwardly when no retry is intended.

    try_once {
      my ($attempts) = @_;
      print "Doing something that might timeout...\n";
      sleep 6;
    }
    ALRM {
      print "Wake up!\n";
    }
    finally {
      my ($attempts, $successful) = @_;
      print $successful ? "Completed\n" : "Timed out\n";
    }
    timeout => 1;

=head1 IMPROVEMENT OVER RAW alarm

=head2 Traditional alarm usage

    local $SIG{ALRM} = sub {
        print "Wake up!\n";
    };

    alarm 1;
    print "Doing something that might timeout...\n";
    sleep 6;
    alarm 0;

This works, but quickly becomes hard to reason about when retries,
cleanup, or shared state are involved.

=head2 Equivalent Try::ALRM version

    try_once {
      print "Doing something that might timeout...\n";
      sleep 6;
    }
    ALRM {
      print "Wake up!\n";
    }
    timeout => 1;

What improved:

=over 4

=item *
Signal handling is localized and declarative

=item *
C<alarm 0> cleanup is automatic

=item *
Retry and finalization hooks are explicit

=item *
Control flow reads top-to-bottom

=back

=head1 DESCRIPTION

C<Try::ALRM> provides try/catch-like semantics around C<alarm>.
Because C<ALRM> signals are localized and expected, they can be treated
as a form of exception without using C<die>.

Internally, this module uses Perl prototypes to coerce lexical blocks
into C<CODE> references, in the same spirit as L<Try::Tiny>. The result
is a structured syntax:

    retry { ... }
    ALRM  { ... }
    finally { ... }

This structure improves readability without changing the underlying
mechanics of C<alarm> or C<$SIG{ALRM}>.

=head1 EXPORTS

This module exports six keywords.

B<NOTE>: Either C<try_once> or C<retry> is required. They are mutually
exclusive.

=head2 try_once BLOCK

Runs BLOCK once with an alarm set to the current timeout value.

If an alarm fires, the C<ALRM> block is executed (if provided), followed
by C<finally>. The alarm is always cleared automatically.

=head2 retry BLOCK

Runs BLOCK up to C<tries> times. Each attempt receives the current
attempt count via C<@_>.

Retries stop when either:

=over 4

=item *
The block completes without an alarm

=item *
The retry limit is reached

=back

=head2 ALRM BLOCK

Optional handler executed when an alarm fires. Receives the current
attempt count.

=head2 finally BLOCK

Optional block executed unconditionally at the end.

Receives:

    my ($attempts, $successful) = @_;

=head2 timeout INT

Getter/setter for the default timeout in seconds.

May also be supplied as a trailing modifier:

    try_once { ... } timeout => 2;

=head2 tries INT

Getter/setter for retry limit.

May also be supplied as a trailing modifier:

    retry { ... } tries => 5;

=head1 PACKAGE ENVIRONMENT

The following package variables are exposed:

=over 4

=item *
C<$Try::ALRM::TIMEOUT>

=item *
C<$Try::ALRM::TRIES>

=back

They may be set globally, lexically (via setters), or temporarily via
trailing modifiers.

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
    } timeout => 5, tries => 10;

This mirrors Perl constructs like C<map> and C<grep>.

=head1 WHY USE THIS MODULE?

C<Try::ALRM> does not replace C<alarm>.
It makes C<alarm>-based logic:

=over 4

=item *
Easier to read

=item *
Safer to modify

=item *
Less error-prone

=item *
More expressive

=back

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

