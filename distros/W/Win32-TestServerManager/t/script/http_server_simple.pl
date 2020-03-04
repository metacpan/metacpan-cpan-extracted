#!perl
use strict;
use warnings;

my $server = Win32::SpawnSimpleServers::TestServer->new(8999);
$server->run;

package Win32::SpawnSimpleServers::TestServer;
use base qw( HTTP::Server::Simple::CGI );
