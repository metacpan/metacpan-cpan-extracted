use strict;
use warnings;

use Test::Tester 0.108;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

plan( skip_all => "running in a bare repository (some files missing): skipping" ) if -d '.git';

require Test::Kwalitee;

check_tests(
    sub {
        # prevent Test::Kwalitee from making a plan
        no warnings 'redefine';
        local *Test::Builder::plan = sub { };
        local *Test::Builder::done_testing = sub { };

        # we are testing ourselves, so we don't want this warning
        local $ENV{_KWALITEE_NO_WARN} = 1;

        Test::Kwalitee->import( tests => [ qw(use_strict has_readme) ] )
    },
    [ map {
            +{
                name => $_,
                depth => 1,
                ok => 1,
                actual_ok => 1,
                type => '',
                diag => '',
            }
        }
        qw(
            has_readme
            use_strict
        )
    ],
    'explicitly included tests tests run exclusively',
);

done_testing;
