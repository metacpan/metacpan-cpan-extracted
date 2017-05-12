use strict;
use Test::More tests => 5;

use WebService::Backlog;
use Encode;

use Data::Dumper;

my $backlog = WebService::Backlog->new(
    space    => 'backlog',
    username => 'guest',
    password => 'guest',
);

{
    ok($backlog->countIssue({ projectId => 20, }) >= 295);
    is($backlog->countIssue({
        projectId => 20,
        milestoneId => 2496,
    }), 7);
    is($backlog->countIssue({
        projectId => 20,
        milestoneId => [2496,2248],
    }), 20);
    is($backlog->countIssue({
        projectId => 20,
        milestoneId => [2496,2248],
        issueTypeId => 81,
    }), 6);
    is($backlog->countIssue({
        projectId => 20,
        milestoneId => [2496,2248],
        issueTypeId => [81,82],
    }), 7);
}

