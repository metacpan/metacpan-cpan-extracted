package Test::Retry;
use strict;
use warnings;
use 5.008_001;
use Test::Builder;
use Time::HiRes qw(sleep);

our $VERSION = '0.01';

our $MAX_RETRIES = 5;
our $RETRY_DELAY = 0.5;

sub import {
    my ($class, %args) = @_;

    my $pkg = caller;
    my $retry_test = _mk_retry_test($args{max}, $args{delay});

    {
        no strict 'refs';
        *{"$pkg\::retry_test"} = $retry_test;
    }

    if (my @names = @{ $args{override} || [] }) {
        $class->_override_test_functions(
            package => $pkg,
            names => \@names,
            retry_test => $retry_test,
        );
    }
}

sub _retry_test_block {
    my ($max, $delay, $block) = @_;

    my $ORIGINAL_ok = \&Test::Builder::ok;

    my $retry;

    no warnings 'redefine';
    local *Test::Builder::ok = sub {
        my ($self, $test, $name) = @_;

        $retry = 0;
        $name = '' unless defined $name;

        if ($test) {
            goto \&$ORIGINAL_ok; # passes
        } elsif (--$max <= 0) {
            $self->diag("test '$name' failing; give up");
            goto \&$ORIGINAL_ok; # fails
        } else {
            $self->diag("test '$name' failing; retry ($max remaining)");
            $retry++;
        }
    };

    &$block;

    while ($retry) {
        sleep $delay;
        &$block;
    }
}

sub _mk_retry_test {
    my ($max, $delay) = @_;

    return sub (&) {
        my $block = shift;

        _retry_test_block(
            $max || $MAX_RETRIES,
            $delay || $RETRY_DELAY,
            $block,
        );
    };
}

sub override {
    my ($class, @names) = @_;
    my $pkg = caller;

    $class->_override_test_functions(
        package => $pkg,
        names => \@names,
    );
}

sub _override_test_functions {
    my ($class, %args) = @_;

    my $pkg = $args{package};
    my @names = @{ $args{names} };
    my $retry_test = $args{retry_test} || $pkg->can('retry_test') || _mk_retry_test();

    foreach my $name (@names) {
        my $original_code = $pkg->can($name);
        my $code = sub (&) {
            my $block = shift;
            $retry_test->(sub {
                my @args = $block->();
                $original_code->(@args);
            });
        };

        no strict 'refs';
        no warnings 'redefine', 'prototype';
        *{"$pkg\::$name"} = $code;
    }
}

1;

__END__

=head1 NAME

Test::Retry - Retry test functions on failure

=head1 SYNOPSIS

  use Test::Retry;

  # Retries for 5 times with 0.5 secs delay each
  retry_test {
      is func_with_some_random_lag(), $expected;
  };

  # or override existing test functions

  BEGIN { Test::Retry->override('is') }

  is { func_with_some_random_lag(), $expected };

=head1 DESCRIPTION

Test::Retry provides feature to retry code until a test succeeds (with retry limits).

Useful for tests which involves I/O and requires some wait to pass, for example.

=head1 IMPORTING

Test::Retry exports one function, namely C<< retry_test >>.

Options below are available when you C<< use >> this module:

=over 4

=item max => $n

The maximum count of retries. Affects the exported C<< retry_test >> function.

Defaults to $Test::Retry::MAX_RETRIES = 5.

=item delay => $floating_secs

The floating seconds after which the next block execution is tried after a failed test.
Affects the exported C<< retry_test >> function.

Defaults to $Test::Retry::RETRY_DELAY = 0.5.

=item override => \@function_names

Calls C<< override >> (see below) at the timing of C<< import >>.

=back

=head1 FUNCTIONS/METHODS

=over 4

=item retry_test { ... }

Makes the given block of code re-run if a test inside it is going to fail.
Retry limit and interval are configurable by importing arguments (see above).

If the test continues to fail and retry count hits the limit, the test really fails.

=item Test::Retry->override(@function_names);

Overrides the existing test functions in caller package by retrying version of them.

Should be called in BEGIN block for prototyping issues.

Arguments must be passed by a coderef that returns arguments passed to the test function.

For example,

  like $io->get(), qr/blahblah/, 'blah';

becomes:

  BEGIN { Test::Retry->override('like') }
  
  like { $io->get(), qr/blahblah/, 'blah' };

Pretty, heh?

=back

=head1 AUTHOR

motemen E<lt>motemen@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
