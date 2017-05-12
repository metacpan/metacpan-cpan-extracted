use strict;
use Test::More tests => 2;

use WebService::Backlog;
use WebService::Backlog::UpdateIssue;
use Encode;
use Data::Dumper;

my $key      = 'DORA-2';
my $statusId = 3;

{
    my $backlog = WebService::Backlog->new(
        space    => 'demo',
        username => 'demo',
        password => 'demo',
    );
    my $updateissue = WebService::Backlog::SwitchStatus->new(
        {
            key      => $key,
            statusId => $statusId,
        }
    );
    ok($updateissue);
    is( Dumper( $updateissue->hash ),
        Dumper( { key => $key, statusId => $statusId } ) );
}

