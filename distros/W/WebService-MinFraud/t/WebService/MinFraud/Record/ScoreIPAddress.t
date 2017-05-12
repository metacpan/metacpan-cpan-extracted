use strict;
use warnings;

use Test::More 0.88;

use WebService::MinFraud::Record::ScoreIPAddress;

my $ip = WebService::MinFraud::Record::ScoreIPAddress->new( risk => .99 );

is( $ip->risk, .99, 'risk' );

done_testing;
