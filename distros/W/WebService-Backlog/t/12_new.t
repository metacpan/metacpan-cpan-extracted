use strict;
use Test::More tests => 3;

use WebService::Backlog;
use WebService::Backlog::UpdateIssue;
use Encode;
use Data::Dumper;

{
    eval { my $backlog = WebService::Backlog->new; };
    if ($@) {
        like( $@, qr/space must be specified/ );
    }
}

{
    eval { my $backlog = WebService::Backlog->new( space => 'demo', ); };
    if ($@) {
        like( $@, qr/username must be specified/ );
    }
}

{
    eval {
        my $backlog =
          WebService::Backlog->new( space => 'demo', username => 'demo' );
    };
    if ($@) {
        like( $@, qr/password must be specified/ );
    }
}
