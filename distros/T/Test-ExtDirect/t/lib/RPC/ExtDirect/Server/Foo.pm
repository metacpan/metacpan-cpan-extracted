package RPC::ExtDirect::Server::Foo;

use base 'RPC::ExtDirect::Server';

our $server_class;

sub new {
    my ($class, %params) = @_;

    $server_class = $class;

    return $class->SUPER::new(%params);
}

1;

