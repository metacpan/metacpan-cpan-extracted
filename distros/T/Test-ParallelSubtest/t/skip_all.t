# Calling skip_all within the subtest

use strict;
use warnings;

use t::MyTest;
use Test::More;

same_as_subtest skip_all_noreason => <<'END';
    use Test::ParallelSubtest;
    use Test::More tests => 1;

    bg_subtest foo => sub {
        plan 'skip_all';
    };
END

same_as_subtest "skip_all_reason_foo" => <<END;
    use Test::ParallelSubtest;
    use Test::More tests => 1;

    bg_subtest foo => sub {
        plan skip_all => 'foo';
    };
END

foreach my $testcase (error_prone_strings()) {
    my ($label, $string) = @$testcase;
    $string =~ s{([\\'])}{\\$1}g;

    same_as_subtest "skip_all_reason_$label" => <<END;
        use Test::ParallelSubtest;
        use Test::More tests => 1;

        bg_subtest foo => sub {
            plan skip_all => '$string';
        };
END
}

done_testing;
