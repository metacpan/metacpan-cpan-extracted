use strict;
use warnings;
use Test2::V0;
use Module::Spy qw(spy_on);

my $file = __FILE__;
my $line;

my $g = spy_on('Test2::Plugin::GitHub::Actions::AnnotateFailedTest', '_issue_error');

my $event = intercept {
    local $ENV{GITHUB_ACTIONS} = 'true';
    require Test2::Plugin::GitHub::Actions::AnnotateFailedTest;
    Test2::Plugin::GitHub::Actions::AnnotateFailedTest->import;

    $line = __LINE__ + 1;
    ok 0;
};
my $call = $g->calls_most_recent;
undef $g;

like $event, array {
    item event 'Ok';
};

is $call, [$file, $line, 'Test failed'], 'annotate with error';

done_testing;
