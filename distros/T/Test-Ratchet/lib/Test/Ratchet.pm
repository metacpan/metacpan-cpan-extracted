use strict;
use warnings;
package Test::Ratchet;

use Exporter::Easy ( EXPORT => [ qw/ratchet/ ] );
use Data::Munge qw(rec);

# ABSTRACT: Mocking helper that swaps out implementations automatically

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

=head1 SYNOPSIS

    use Test::Ratchet;
    use Test::MockModule;
    use Test::More;

    my $mock = Test::MockModule->new('Some::Module');
    $mock->mock( magic_method => ratchet(
        \&first_implementation,
        \&second_implementation,
        ...
    ));

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

=head1 EXPORTS

This module exports L</ratchet> by default - this is the only export.

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

=cut

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


1;
