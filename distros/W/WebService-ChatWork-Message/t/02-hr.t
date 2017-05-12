use strict;
use warnings;
use WebService::ChatWork::Message;
use Test::More tests => 1;

my $hr = WebService::ChatWork::Message->new( "hr" );
is( "$hr", "[hr]" );
