use strict;
use lib 't';
use SingleClientServer;
use Talkers;

my $path = shift;

SingleClientServer::run_local(\&Talkers::echo, $path);
