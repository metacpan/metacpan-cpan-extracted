use strict;
use warnings;

use Test::More 0.88;

use WebService::MinFraud::Record::Disposition;

my $disposition = WebService::MinFraud::Record::Disposition->new(
    action => 'accept',
    reason => 'default',
);

is( $disposition->action, 'accept',  '$disposition->action' );
is( $disposition->reason, 'default', '$disposition->reason' );

done_testing;
