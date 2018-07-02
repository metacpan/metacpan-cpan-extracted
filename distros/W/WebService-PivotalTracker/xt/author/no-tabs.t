use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/WebService/PivotalTracker.pm',
    'lib/WebService/PivotalTracker/Client.pm',
    'lib/WebService/PivotalTracker/Comment.pm',
    'lib/WebService/PivotalTracker/Entity.pm',
    'lib/WebService/PivotalTracker/Label.pm',
    'lib/WebService/PivotalTracker/Me.pm',
    'lib/WebService/PivotalTracker/Person.pm',
    'lib/WebService/PivotalTracker/Project.pm',
    'lib/WebService/PivotalTracker/ProjectIteration.pm',
    'lib/WebService/PivotalTracker/ProjectMembership.pm',
    'lib/WebService/PivotalTracker/PropertyAttributes.pm',
    'lib/WebService/PivotalTracker/Story.pm',
    'lib/WebService/PivotalTracker/Types.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t',
    't/fixtures/6dacc86cc06f5740ef4d9ae3cd8624cb.json',
    't/lib/Test/UA.pm'
);

notabs_ok($_) foreach @files;
done_testing;
