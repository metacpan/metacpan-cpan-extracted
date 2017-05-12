use strict;
use warnings;
use WebService::ChatWork::Message;
use Test::More tests => 2;

my $picon = WebService::ChatWork::Message->new( picon => ( account_id => 3 ) );
is( "$picon", "[picon:3]" );

my $common_used_picon = WebService::ChatWork::Message->new( picon => 4 );
is( "$common_used_picon", "[picon:4]" );
