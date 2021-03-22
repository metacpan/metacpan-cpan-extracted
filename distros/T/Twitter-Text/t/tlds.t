use Test2::V0;
no if $^V lt v5.13.9, 'warnings', 'utf8'; ## no critic (ValuesAndExpressions::ProhibitMismatchedOperators)

use Test2::Plugin::NoWarnings;
BEGIN {
    eval { ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
        require Test2::Plugin::GitHub::Actions::AnnotateFailedTest;
        Test2::Plugin::GitHub::Actions::AnnotateFailedTest->import;
    };
}

use Twitter::Text::Util;
use Twitter::Text;

my $yaml = load_yaml("tlds.yml");

subtest generic => sub {
    my $testcases = $yaml->[0]->{tests}->{generic};

    for my $testcase (@$testcases) {
        my $parse_result = extract_urls($testcase->{text});
        my $expected     = $testcase->{expected};
        is(
            $parse_result,
            $expected,
            $testcase->{description},
        );
    }
};

subtest country => sub {
    my $testcases = $yaml->[0]->{tests}->{country};

    for my $testcase (@$testcases) {
        my $parse_result = extract_urls($testcase->{text});
        my $expected     = $testcase->{expected};
        is(
            $parse_result,
            $expected,
            $testcase->{description},
        );
    }
};

done_testing;
