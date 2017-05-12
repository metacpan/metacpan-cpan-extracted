use strict;
use warnings;
use WebService::ChatWork::Message;
use Test::More tests => 1;

my $message = WebService::ChatWork::Message->new( "asdf" );

is( "$message", "asdf" );
