use strict;
use warnings;
use Test2::V0;
use Module::Spy qw(spy_on);

my $g = spy_on('Test2::Plugin::GitHub::Actions::AnnotateFailedTest', '_issue_error');

intercept {
    local $ENV{GITHUB_ACTIONS} = undef;
    require Test2::Plugin::GitHub::Actions::AnnotateFailedTest;
    Test2::Plugin::GitHub::Actions::AnnotateFailedTest->import;

    ok 0, 'failed';
};

ok ! $g->called, 'disabled when not in GitHub Actions';

done_testing;
