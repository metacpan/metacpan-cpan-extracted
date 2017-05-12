package test::class;

use RPC::ExtDirect Action => 'test';
use RPC::ExtDirect::Server::Foo;

sub get_server_class : ExtDirect(0) {
    return $RPC::ExtDirect::Server::Foo::server_class;
}

1;

