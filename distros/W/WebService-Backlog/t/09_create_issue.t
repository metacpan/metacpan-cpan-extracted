use strict;
use Test::More tests => 7;

use WebService::Backlog;
use WebService::Backlog::CreateIssue;
use Encode;
use Data::Dumper;

my $summary = 'Issue created by WebService::Backlog!';

{
    my $backlog = WebService::Backlog->new(
        space    => 'demo',
        username => 'demo',
        password => 'demo',
    );
    my $newissue = WebService::Backlog::CreateIssue->new(
        {
            projectId => 5432,
            summary   => $summary,
        }
    );
    ok($newissue);
    is( Dumper( $newissue->hash ),
        Dumper( { projectId => 5432, summary => $summary } ) );
}

{
    my $newissue = WebService::Backlog::CreateIssue->new(
        {
            projectId  => 5432,
            summary    => $summary,
            assignerId => 331,
        }
    );
    ok($newissue);
    is(
        Dumper( $newissue->hash ),
        Dumper( { projectId => 5432, summary => $summary, assignerId => 331 } )
    );
}

SKIP: {
    skip "no space, username, password, projectid set, skipped.", 3
      unless ( $ENV{BACKLOG_SPACE}
        and $ENV{BACKLOG_USERNAME}
        and $ENV{BACKLOG_PASSWORD}
        and $ENV{BACKLOG_PROJECT_ID} );

    my $backlog = WebService::Backlog->new(
        space    => $ENV{BACKLOG_SPACE},
        username => $ENV{BACKLOG_USERNAME},
        password => $ENV{BACKLOG_PASSWORD},
    );
    my $newissue = WebService::Backlog::CreateIssue->new(
        {
            projectId => $ENV{BACKLOG_PROJECT_ID},
            summary   => $summary,
        }
    );
    ok($newissue);
    is(
        Dumper( $newissue->hash ),
        Dumper(
            { projectId => $ENV{BACKLOG_PROJECT_ID}, summary => $summary }
        )
    );

    my $created = $backlog->createIssue($newissue);
    ok( defined $newissue );
    is( $created->summary, $summary );
}

