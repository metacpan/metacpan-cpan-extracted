# Test using custom classes instead of RPC::ExtDirect::Server/Client

use strict;
use warnings;
no  warnings 'uninitialized', 'once';

use Test::More tests => 2;

use Test::ExtDirect;

use lib 't/lib';
use RPC::ExtDirect::Server::Foo;
use test::class;

my ($host, $port) = start_server(
    server_class => 'RPC::ExtDirect::Server::Foo',
    static_dir   => '/tmp/',
);

my $client = Test::ExtDirect::_get_client(
    host         => $host,
    port         => $port,
    client_class => 'RPC::ExtDirect::Client::Foo',
);

is ref $client, 'RPC::ExtDirect::Client::Foo', "Client class";

my $server_class = call_extdirect(
    action => 'test',
    method => 'get_server_class',
);

is $server_class, 'RPC::ExtDirect::Server::Foo', "Server class";

