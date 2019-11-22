use 5.10.1;
use strict;
use warnings;

use Test::More tests=>2;

BEGIN { use_ok( 'Zeek::Log::Parse' ); }

my $parse = Zeek::Log::Parse->new({file => 'logs/ssl.log', empty_as_undef => 1});
my $line = $parse->getLine();
is($line->{client_cert_chain_fuids}, undef, "client_cert_chain_fuids");

