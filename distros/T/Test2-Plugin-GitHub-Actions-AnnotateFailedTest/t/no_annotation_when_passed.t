use strict;
use warnings;
use Test2::V0;
use Module::Spy qw(spy_on);

my $g = spy_on('Test2::Plugin::GitHub::Actions::AnnotateFailedTest', '_issue_error');

intercept {
    local $ENV{GITHUB_ACTIONS} = 'true';
    require Test2::Plugin::GitHub::Actions::AnnotateFailedTest;
    Test2::Plugin::GitHub::Actions::AnnotateFailedTest->import;

    ok 1;
    is 1, 1;
    pass 'ok';
};

ok ! $g->called, 'no annotation';

done_testing;
