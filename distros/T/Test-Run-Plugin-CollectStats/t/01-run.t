#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use Test::Trap qw( trap $trap :flow:stderr(systemsafe):stdout(systemsafe):warn );

package MyTestRun;

use base 'Test::Run::Plugin::CollectStats';
use base 'Test::Run::Obj';

package main;

{
    my $tester = MyTestRun->new(
        {
            test_files =>
            [
                "t/sample-tests/simple",
                "t/sample-tests/todo-with-10-tests",
            ],
        }
        );

    trap {
    $tester->runtests();
    };

    # TEST
    is ($tester->get_num_collected_tests(),
        2,
        "Length of the recorded test files data"
    );

    # TEST
    is ($tester->find_test_file_idx_by_filename("t/sample-tests/simple"),
        0,
        "t/sample-test/simple is the 0th element"
    );

    # TEST
    is ($tester->find_test_file_idx_by_filename("t/sample-tests/todo-with-10-tests"),
        1,
        "t/sample-test/todo-with-10-tests is the 1th element"
    );

    # TEST
    is ($tester->get_recorded_test_file_data(0)->summary_object->ok(),
        5,
        "simple 'ok' count"
    );

    # TEST
    is ($tester->get_filename_test_data("t/sample-tests/simple")
               ->summary_object->ok(),
        5,
        "simple 'ok' count by filename"
    );

    # TEST
    is ($tester->get_filename_test_data("t/sample-tests/todo-with-10-tests")
               ->summary_object->ok(),
        10,
        "todo 'ok' count by filename"
    );
}

