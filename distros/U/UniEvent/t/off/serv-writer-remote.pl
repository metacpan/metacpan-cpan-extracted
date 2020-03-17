use strict;
use lib 't';
use SingleClientServer;

my $line = shift;

SingleClientServer::run_remote(
  sub {
    my $client = $_[0];
    print $client $line;
  });
