use strict;
use lib 't';
use SingleClientServer;

SingleClientServer::run_remote(
  sub {
    my $client = $_[0];
    while (sysread $client, my $data, 1) {
      syswrite $client, $data;
    }
  });
