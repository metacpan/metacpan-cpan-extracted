use strict;
use warnings;

use Test::More;
use Time::ETA;
use Time::HiRes qw(
    gettimeofday
);

my $true = 1;
my $false = '';

=head1 get_tests

Returns array with hashes:

    (
        {
            value => undef,
            pz => $false,    # what should _is_positive_integer_or_zero() return
            p => $false,     # what should _is_positive_integer() return
        },
        ...
    )

=cut

sub get_tests {

    my @tests = (
        {
            value => undef,
            pz => $false,
            p => $false,
        },
        {
            value => 'mememe',
            pz => $false,
            p => $false,
        },
        {
            value => -3,
            pz => $false,
            p => $false,
        },
        {
            value => 0,
            pz => $true,
            p => $false,
        },
        {
            value => 1,
            pz => $true,
            p => $true,
        },
        {
            value => 1.2,
            pz => $false,
            p => $false,
        },
    );

    return @tests;
}

sub check_sub_is_positive_integer_or_zero {
    foreach my $test (get_tests()) {

        my $value = defined $test->{value} ? $test->{value} : '';

        is(Time::ETA::_is_positive_integer_or_zero(undef, $test->{value}), $test->{pz}, "_is_positive_integer_or_zero($value)");
    }
}

sub check_sub_is_positive_integer {
    foreach my $test (get_tests()) {

        my $value = defined $test->{value} ? $test->{value} : '';

        is(Time::ETA::_is_positive_integer(undef, $test->{value}), $test->{p}, "_is_positive_integer($value)");
    }
}

sub main {
    check_sub_is_positive_integer_or_zero();
    check_sub_is_positive_integer();
    done_testing();
}

main ();
