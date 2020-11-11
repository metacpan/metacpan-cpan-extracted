use Test2::V0;
use Test2::Plugin::GitHub::Actions::AnnotateFailedTest;

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
