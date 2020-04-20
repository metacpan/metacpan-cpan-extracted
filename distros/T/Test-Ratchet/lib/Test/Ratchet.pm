use strict;
use warnings;
package Test::Ratchet;

use Exporter::Easy ( OK => [ qw/ratchet clank/ ] );
use Data::Munge qw(rec);
use Scalar::Util qw(refaddr);

our $VERSION = '0.005';

# ABSTRACT: Mocking helper that swaps out implementations automatically


sub ratchet {
    my @subrefs = @_;

    my $ratchet = rec {
        my $recurse = shift;
        if (! @subrefs) {
            die "Tried to run a ratchet but there was nothing left to do!";
        }

        my $now = $subrefs[0];

        # simple scalar should be a number. Run the next item as a subref if
        # that number is not 0. If it's reached 0, shift them both off and redo.
        # Or it's an asterisk, in which case do the next subref forever.
        if (not ref $now) {
            if ($now eq '*') {
                return $subrefs[1]->(@_);
            }

            if ($now > 0) {
                $now = $subrefs[1];
                $subrefs[0]--;
                return $now->(@_);
            }
            else {
                shift @subrefs; shift @subrefs;
                # redo
                return $recurse->(@_);
            }
        }

        else {
            shift @subrefs;
        }

        $now->(@_);
    };
}


sub clank($) {
    my $subref = shift;
    my $caller = sprintf "%s, line %s", (caller)[1,2];
    my $clank = rec { my $rec = shift; delete $Test::Ratchet::Clank::CLANK{ refaddr $rec }; &$subref };
    $Test::Ratchet::Clank::CLANK{refaddr $clank} = $caller;
    bless $clank, "Test::Ratchet::Clank";
}

package Test::Ratchet::Clank;

use Scalar::Util qw(refaddr);

our %CLANK;

sub DESTROY {
    my $self = shift;
    require Test::More;
    Test::More::fail("A Clank was never run! Created at " . $CLANK{refaddr $self}) if $CLANK{ refaddr $self };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Ratchet - Mocking helper that swaps out implementations automatically

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    use Test::Ratchet qw(ratchet clank);
    use Test::MockModule;
    use Test::More;

    use Some::Module;

    my $mock = Test::MockModule->new('Some::Module');
    $mock->mock( magic_method => ratchet(
        \&first_implementation,
        \&second_implementation,

        # A clank *must* be run, or the test fails!
        clank \&third_implementation,
    ));

    # In reality, you will have no control over the use of this object - which
    # is the purpose of the module in the first place! The actual use of this
    # object would be deep in the code you are actually testing.
    my $obj = Some::Module->new;

    $obj->magic_method('foo'); # Returns { something => 'relevant' }
    $obj->magic_method('bar'); # Returns { something => 'else' }

    # This test will fail! magic_method was only run twice, but there are three
    # implementations - and the third one is a clank! Failing to run a clank
    # causes a test failure.
    done_testing;

    sub first_implementation {
        my $self = shift;
        my $arg1 = shift;

        is $arg1, "foo", "First call passed foo to magic_method";

        return { something => 'relevant' }
    }

    sub second_implementation {
        my $self = shift;
        my $arg1 = shift;

        is $arg1, "bar", "Second call passed bar to magic_method";

        return { something => 'else' }
    }


    sub third_implementation {
        my $self = shift;
        my $arg1 = shift;

        is $arg1, "zip", "Third call passed zip to magic_method";

        return { something => 'different' }
    }

=head1 DESCRIPTION

Testing sucks, especially when you have to deal with third-party code,
especially when you didn't have a choice about which third-party code you are
relying on.

This module solves one specific difficulty of doing so: when you have an atomic
operation that ends up running the same function multiple times with different
data.

An example you say? The rationale for writing this module was to test a module
that used L<REST::Client/PATCH> twice in the same function, but sending
different data to different endpoints (because Reasons). Since the function
being tested could not be subdivided I<by> the test, it made sense to set up a
sequence of expectations before the test instead.

This module, then, simply exports the L</ratchet> function, which sets up
a queue of subrefs to handle a mocked function.

I'm sure it has other purposes too.

=head1 EXPORTS

This module exports L</ratchet> and L</clank> on request.

=head2 ratchet

Accepts any number of subrefs, and returns a single subref that will run through
this queue each time it is called.

Additionally, non-refs can be used to repeat an entry rather than creating
multiple refs to the same thing:

=over

=item N

A number will repeat the subref after it N times

=item Z<>*

An asterisk will repeat the subref after it indefinitely.

=back

If the mocked sub is called and the queue has expired, it will die.

=head2 clank

A clank is a subref that outputs a test failure if it is not run at least once
before it goes out of scope. You can use it in your ratchet, or independently.

    ratchet (
        clank \&must_run,
        \&might_run
    );

To keep the interface simple the test failure uses a generic message that tells
you as best as it can the script and line number at which the clank appears.

I recommend that you ensure your clank goes out of scope before you end your
test suite, so that you don't accidentally output your test summary before it
has a chance to fail.

    {
        my $mock = Test::MockModule->new(...);
        $mock->mock('method', clank sub { ... });
        ... tests ...
    }

    done_testing;

=head1 AUTHOR

Alastair Douglas <altreus@altre.us>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Alastair Douglas.

This is free software, licensed under:

  The MIT (X11) License

=cut
