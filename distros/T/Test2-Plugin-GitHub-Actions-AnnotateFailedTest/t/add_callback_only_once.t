use strict;
use warnings;
use Test2::V0;
use Module::Spy qw(spy_on);

my $g = spy_on('Test2::Plugin::GitHub::Actions::AnnotateFailedTest', '_issue_error');

intercept {
    local $ENV{GITHUB_ACTIONS} = 'true';
    for (1..3) {
        require Test2::Plugin::GitHub::Actions::AnnotateFailedTest;
        Test2::Plugin::GitHub::Actions::AnnotateFailedTest->import;
    }

    ok 0, 'failed';
};

is $g->calls_count, 1, 'annotate only once';

done_testing;
