# Assigning strange names to background subtests

use strict;
use warnings;

use t::MyTest;
use Test::More;

foreach my $testcase (error_prone_strings()) {
    my ($label, $string) = @$testcase;
    $string =~ s{([\\'])}{\\$1}g;

    same_as_subtest "bg_subtest_name_$label" => <<END;
        use Test::ParallelSubtest;
        use Test::More tests => 1;

        bg_subtest '$string' => sub {
            ok 1, "is ok";
            done_testing;
        };
END

    same_as_subtest "todoblock_bg_subtest_name_$label" => <<END;
        use Test::ParallelSubtest;
        use Test::More tests => 1;

        TODO: {
            local \$TODO = 'Reason';

            bg_subtest '$string' => sub {
                ok 1, "is ok";
                done_testing;
            };
        };
END

    same_as_subtest "todostart_bg_subtest_name_$label" => <<END;
        use Test::ParallelSubtest;
        use Test::More tests => 1;

        Test::Builder->new->todo_start('Reason');

        bg_subtest '$string' => sub {
            ok 1, "is ok";
            done_testing;
        };
        
        Test::Builder->new->todo_end;
END

}

done_testing;
