use strict;
use warnings;
use Test2::Plugin::GitHub::Actions::AnnotateFailedTest;
use Test2::V0;
use Module::Spy qw(spy_on);

my $file = __FILE__;
my $line;

my $g = spy_on('Test2::Plugin::GitHub::Actions::AnnotateWarnings', '_issue_warning');

my $event = intercept {
    local $ENV{GITHUB_ACTIONS} = 'true';
    require Test2::Plugin::GitHub::Actions::AnnotateWarnings;
    Test2::Plugin::GitHub::Actions::AnnotateWarnings->import;

    $line = __LINE__ + 1;
    warn 'oops';
    ok 1;
};
my $call = $g->calls_most_recent;
undef $g;

like $event, array {
    item event 'Ok';
};

is $call, [$file, $line, "oops at $file line $line."], 'annotate with warning';

done_testing;
