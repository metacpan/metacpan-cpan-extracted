use strict;
use Test::More tests => 9;

use WebService::Backlog;
use Encode;

use Data::Dumper;

my $backlog = WebService::Backlog->new(
    space    => 'backlog',
    username => 'guest',
    password => 'guest',
);

{
    my $issues = $backlog->findIssue({
        projectId => 20,
        sort => 'CREATED',
        order => 1, 
    }); 
    ok(scalar(@{$issues}) == 100);
    is($issues->[0]->key, 'BLG-1');
}
{
    my $issues = $backlog->findIssue({
        projectId => 20,
        milestoneId => 2496,
        sort => 'CREATED',
        order => 0, 
    });
    ok(scalar(@{$issues}) == 7);
    is($issues->[0]->key, 'BLG-240');
    is($issues->[6]->key, 'BLG-226');
}
{
    my $issues = $backlog->findIssue({
        projectId => 20,
        milestoneId => 2496,
        sort => 'CREATED',
        order => 1,
        offset => 2,
        limit => 3,
    });
    ok(scalar(@{$issues}) == 3);
    is($issues->[0]->key, 'BLG-230');
    is($issues->[1]->key, 'BLG-232');
    is($issues->[2]->key, 'BLG-233');
}


