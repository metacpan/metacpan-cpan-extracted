use strict;
use warnings;
use Test::More;
use Test::Exception;

use Test::SetupTeardown;

{ # running everything when $ENV{TEST_ST_ONLY} is not set

    my $environment = Test::SetupTeardown->new;
    my $did_i_run = 0;

    delete $ENV{TEST_ST_ONLY};

    $environment->run_test('this is the description',
                           sub { $did_i_run = 1 });

    is($did_i_run, 1,
       q{... and environment 1 runs the test when the env variable is not set});

    $environment->run_test('this is the other description',
                           sub { $did_i_run = 2 });

    is($did_i_run, 2,
       q{... and so does environment 2});

}

{ # running only one when $ENV{TEST_ST_ONLY} is set

    my $environment = Test::SetupTeardown->new;
    my $did_i_run = 0;

    $ENV{TEST_ST_ONLY} = 'this is the description';

    $environment->run_test('this is the description',
                           sub { $did_i_run = 1 });

    is($did_i_run, 1,
       q{... and environment 1 runs the test when the env variable is set to its description});

    $environment->run_test('this is the other description',
                           sub { $did_i_run = 2 });

    is($did_i_run, 1,
       q{... and environment 2 does not run when the env variable does not match});

}

done_testing;
