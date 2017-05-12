use strict;
use warnings;

use Test::More;
use Time::ETA;
use Time::HiRes qw(
    gettimeofday
);

my $true = 1;
my $false = '';

sub check_sub_check_gettimeofday {

    my $gettimeofday_tests = [
        {
            value => [gettimeofday()],
            name => 'start time',
            is_correct => $true,
        },
        {
            value => [gettimeofday()],
            name => undef,
            is_correct => $false,  # it is incorrect, because no name is specified
        },
    ];

    foreach my $test (@{$gettimeofday_tests}) {


        my $result;
        eval {
            $result = Time::ETA::_check_gettimeofday(
                undef,
                name => $test->{name},
                value => $test->{value},
            );
        };

        if ($test->{is_correct}) {
            is($@, "", "_check_gettimeofday() run successfully");
        } else {
            like(
                $@,
                qr/Expected to get 'name'/,
                "_check_gettimeofday() fail on error",
            );
        }

    }
}

sub main {
    check_sub_check_gettimeofday();
    done_testing();
}

main ();
