use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/WebService/PivotalTracker.pm',
    'lib/WebService/PivotalTracker/Client.pm',
    'lib/WebService/PivotalTracker/Comment.pm',
    'lib/WebService/PivotalTracker/Entity.pm',
    'lib/WebService/PivotalTracker/Label.pm',
    'lib/WebService/PivotalTracker/Me.pm',
    'lib/WebService/PivotalTracker/Project.pm',
    'lib/WebService/PivotalTracker/ProjectIteration.pm',
    'lib/WebService/PivotalTracker/PropertyAttributes.pm',
    'lib/WebService/PivotalTracker/Story.pm',
    'lib/WebService/PivotalTracker/Types.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t',
    't/fixtures/services/v5/stories/120292647.json',
    't/lib/Test/UA.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
