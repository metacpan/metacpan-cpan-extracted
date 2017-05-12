use strict;
use warnings;

use Time::ETA;
use Test::More;

sub run_without_milestones {
    eval {
        my $te = Time::ETA->new();
    };

    like($@, qr/Expected to get parameter 'milestones'/, "Can't create object without mandatory parameter 'milestones'");
}

sub run_with_incorrect_milestones {
    my @incorrect_numbers = (
        "-1",
        "0",
        "+0",
        "1.",
        "1.0",
        ".1",
        "0.1",
        "1,1",
        "n1",
        "1n",
        "n1n",
        "Inf",
        "Infinity",
        "NaN",
        "0 but true",
    );

    foreach my $number (@incorrect_numbers) {
        eval {
            my $te = Time::ETA->new(
                milestones => $number,
            );
        };

        like(
            $@,
            qr/Parameter 'milestones' should be positive integer/,
            "Constructor should not work with 'milestones' value '$number'"
        );
    }
}

sub run_with_correct_milestones {
    my @correct_numbers = (
        "1",
        "+1",
    );

    foreach my $number (@correct_numbers) {
        eval {
            my $te = Time::ETA->new(
                milestones => $number,
            );
        };

        is($@, '', "Created object with 'milestones' value '$number'");
    }
}

sub main {
    run_without_milestones();
    run_with_incorrect_milestones();
    run_with_correct_milestones();

    done_testing();
}

main();
