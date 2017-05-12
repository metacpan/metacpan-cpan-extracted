use strict;
use Test::More tests => 4;

use WebService::Backlog;
use WebService::Backlog::UpdateIssue;
use Encode;
use Data::Dumper;

my $key     = 'DORA-2';
my $summary = 'Issue updated by WebService::Backlog!';

{
    my $backlog = WebService::Backlog->new(
        space    => 'demo',
        username => 'demo',
        password => 'demo',
    );
    my $updateissue = WebService::Backlog::UpdateIssue->new(
        {
            key     => $key,
            summary => $summary,
        }
    );
    ok($updateissue);
    is( Dumper( $updateissue->hash ),
        Dumper( { key => $key, summary => $summary } ) );
}
{
    my $updateissue = WebService::Backlog::UpdateIssue->new(
        {
            key        => $key,
            summary    => $summary,
            assignerId => "",
        }
    );
    ok($updateissue);
    is( Dumper( $updateissue->hash ),
        Dumper( { key => $key, summary => $summary, assignerId => "" } ) );
}

