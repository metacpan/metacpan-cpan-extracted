use 5.006;
use strict;
use warnings;

package Try::Tiny::Retry;
# ABSTRACT: Extends Try::Tiny to allow retries
our $VERSION = '0.004'; # VERSION

use parent 'Exporter';
our @EXPORT      = qw/retry retry_if on_retry try catch finally/;
our @EXPORT_OK   = ( @EXPORT, qw/delay delay_exp/ );
our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

use Carp;
$Carp::Internal{ +__PACKAGE__ }++;

use Try::Tiny;

BEGIN {
    eval "use Sub::Name; 1" or *{subname} = sub { 1 }
}

our $_DEFAULT_DELAY = 1e5; # to override for testing

sub delay(&;@) {           ## no critic
    my ( $block, @rest ) = @_;
    return ( bless( \$block, 'Try::Tiny::Retry::Delay' ), @rest, );
}

sub on_retry(&;@) {        ## no critic
    my ( $block, @rest ) = @_;
    return ( bless( \$block, 'Try::Tiny::Retry::OnRetry' ), @rest, );
}

sub retry_if(&;@) {        ## no critic
    my ( $block, @rest ) = @_;
    return ( bless( \$block, 'Try::Tiny::Retry::RetryIf' ), @rest, );
}

sub delay_exp(&;@) {       ## no critic
    my ( $params, @rest )  = @_;
    my ( $n,      $scale ) = $params->();

    require Time::HiRes;

    return delay {
        return if $_[0] >= $n;
        Time::HiRes::usleep( int rand( $scale * ( 1 << ( $_[0] - 1 ) ) ) );
    }, @rest;
}

sub retry(&;@) {           ## no critic
    my ( $try, @code_refs ) = @_;

    # name the block if we have Sub::Name
    my $caller = caller;
    subname( "${caller}::retry {...} " => $try );

    # we need to save this here to ensure retry block is evaluated correctly
    my $wantarray = wantarray;

    # find labeled blocks in the argument list: retry_if and delay tag by blessing
    # a scalar reference to the code block reference
    my ( $delay, $on_retry, @conditions, @rest );

    foreach my $code_ref (@code_refs) {
        if ( ref($code_ref) eq 'Try::Tiny::Retry::RetryIf' ) {
            push @conditions, $$code_ref;
        }
        elsif ( ref($code_ref) eq 'Try::Tiny::Retry::OnRetry' ) {
            croak 'A retry() may not be followed by multiple on_retry blocks'
              if $on_retry;
            $on_retry = $$code_ref;
        }
        elsif ( ref($code_ref) eq 'Try::Tiny::Retry::Delay' ) {
            croak 'A retry() may not be followed by multiple delay blocks'
              if $delay;
            $delay = $$code_ref;
        }
        else {
            push @rest, $code_ref;
        }
    }

    # default retry 10 times with default exponential backoff
    if ( !defined $delay ) {
        my ($code_ref) = delay_exp { 10, $_DEFAULT_DELAY };
        $delay = $$code_ref;
    }

    # execute code block and retry as necessary
    my @ret;
    my $retry = sub {
        my $count = 0;
        RETRY: {
            $count++;
            my ( $redo, $err );
            try {
                # evaluate the try block in the correct context
                if ($wantarray) {
                    @ret = $try->();
                }
                elsif ( defined $wantarray ) {
                    $ret[0] = $try->();
                }
                else {
                    $try->();
                }
            }
            catch {
                $err = $_;
                # if there are conditions, rethrow unless at least one is met
                if (@conditions) {
                    my $met = 0;
                    for my $c (@conditions) {
                        local $_ = $err; # protect from modification
                        $met++ if $c->($count);
                    }
                    die $err unless $met;
                }
                # rethow if delay function signals stop with undef
                die $err unless defined $delay->($count);
                # if here, then we want to try again
                $redo++;
            };
            if ( defined $on_retry && $redo ) {
                local $_ = $err;
                $on_retry->($count);
            }

            redo RETRY if $redo;
        }
        return $wantarray ? @ret : $ret[0];
    };

    # call "&try" to bypass the prototype check
    return &try( $retry, @rest );
}

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Try::Tiny::Retry - Extends Try::Tiny to allow retries

=head1 VERSION

version 0.004

=head1 SYNOPSIS

Use just like L<Try::Tiny>, but with C<retry> instead of C<try>. By default,
C<retry> will try 10 times with exponential backoff:

    use Try::Tiny::Retry;

    retry     { ... }
    catch     { ... }
    finally   { ... };

You can retry only if the error matches some conditions:

    use Try::Tiny::Retry;

    retry     { ... }
    retry_if  { /^could not connect/ }
    catch     { ... };

You can customize the number of tries and delay timing:

    use Try::Tiny::Retry ':all';

    retry     { ... }
    delay_exp { 5, 1e6 } # 5 tries, 1 second exponential-backoff
    catch     { ... };

You can run some code before each retry:

    use Try::Tiny::Retry;

    retry     { ... }
    on_retry  { ... }
    catch     { ... };

=head1 DESCRIPTION

This module extends L<Try::Tiny> to allow for retrying a block of code several
times before failing.  Otherwise, it works seamlessly like L<Try::Tiny>.

By default, Try::Tiny::Retry exports C<retry> and C<retry_if>, plus C<try>,
C<catch> and C<finally> from L<Try::Tiny>.  You can optionally export C<delay>
or C<delay_exp>.  Or you can get everything with the C<:all> tag.

=head1 FUNCTIONS

=head2 retry

    retry    { ... }  # code that might fail
    retry_if { ... }  # conditions to be met for a retry
    delay    { ... }  # control repeats and intervals between retries
    catch    { ... }; # handler if all retries fail

The C<retry> function works just like C<try> from L<Try::Tiny>, except that if
an exception is thrown, the block may be executed again, depending on the
C<retry_if> and C<delay> blocks.

If one or more C<retry_if> blocks are provided, as long as any of them evaluate
to true, a retry will be attempted unless the result of the C<delay> block
indicates otherwise.  If none of them evaluate to true, no retry will be
attempted and the C<delay> block will not be called.

If no C<delay> block is provided, the default will be 10 tries with a random
delay up to 100 milliseconds with an exponential backoff.  (See L</delay_exp>.)
This has an expected cumulative delay of around 25 seconds if all retries fail.

=head2 retry_if

    retry    { ... }
    retry_if { /^could not connect/ }
    catch    { ... };

A C<retry_if> block controls whether a retry should be attempted after an
exception (assuming there are any retry attempts remaining).

The block is passed the cumulative number of attempts as an argument.  The
exception caught is provided in C<$_>, just as with C<catch>.  It should
return a true value if a retry should be attempted.

Multiple C<retry_if> blocks may be provided.  Only one needs to evaluate
to true to enable a retry.

Using a C<retry_if> block based on the retry count is an alternate way to allow
B<fewer> (but not greater) tries than the default C<delay> function, but with
the default exponential backoff behavior.  These are effectively equivalent:

    retry     { ... }
    retry_if  { shift() < 3 };

    retry     { ... }
    delay_exp { 3, 1e5 };

If you wish the exception to be rethrown if all C<retry_if> blocks return
false, you must use a C<catch> block to do so:

    retry    { ... }
    retry_if { /^could not connect/ }
    catch    { die $_ };

=head2 on_retry

    retry    { ... }
    on_retry { $state->reset() }
    catch    { ... };

The C<on_retry> block runs before each C<retry> block after the first attempt.
The exception caught is provided in C<$_>.  The block is passed the cumulative
number of attempts as an argument.  The return value is ignored.

Only one C<on_retry> block is allowed.

=head2 delay

    retry { ... }
    delay {
        return if $_[0] >= 3; # only three tries
        sleep 1;              # constant delay between tries
    }
    catch { ... };

The C<delay> block controls the number of attempts and the delay between
attempts.

The block is passed the cumulative number of attempts as an argument.  If the
C<delay> block returns an undefined value, no further retries will be made.

If you wish the exception to be rethrown if all attempts fail, you must use a
C<catch> block to do so:

    retry    { ... }
    delay    { ... }
    catch    { die $_ };

Only one C<delay> block is allowed.

=head2 delay_exp

    retry     { ... }
    delay_exp { 3, 10000 } # 3 tries, 10000 µsec
    catch     { ... };

This function is an exponential-backoff delay-function generator.  The delay
between attempts is randomly selected between 0 and an upper bound. The upper
bound doubles after each failure.

It requires a code block as an argument.  The block will be evaluated in list
context and must return two elements.  The first element is the number of tries
allowed.  The second element is the starting upper bound in B<microseconds>.

Given number of tries C<N> and upper bound C<U>, the expected cumulative
delay time if all attempts fail is C<0.5 * U * ( 2^(N-1) - 1 )>.

=for Pod::Coverage BUILD

=head1 SEE ALSO

There are other retry modules on CPAN, but none of them worked seamlessly with
L<Try::Tiny>.

=over 4

=item *

L<Action::Retry> — OO (Moo) or functional; various delay strategies; supports conditions

=item *

L<AnyEvent::Retry> — OO (Moose) and event-driven; various delay strategies

=item *

L<Attempt> — functional; simple retry count with constant sleep time

=item *

L<Retry> — OO (Moose) with fixed exponential backoff; supports callbacks on every iteration

=item *

L<Sub::Retry> — functional; simple retry count with constant sleep time; supports conditions

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Try-Tiny-Retry/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Try-Tiny-Retry>

  git clone https://github.com/dagolden/Try-Tiny-Retry.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTOR

David Steinbrunner <dsteinbrunner@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
