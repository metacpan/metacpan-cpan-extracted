use strict;
use warnings;
use WebService::ChatWork::Message;
use Test::More tests => 2;

my $piconname = WebService::ChatWork::Message->new( piconname => ( account_id => 3 ) );
is( "$piconname", "[piconname:3]" );

my $common_used_piconname = WebService::ChatWork::Message->new( piconname => 4 );
is( "$common_used_piconname", "[piconname:4]" );
