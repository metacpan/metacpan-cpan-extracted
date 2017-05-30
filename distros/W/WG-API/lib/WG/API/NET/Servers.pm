package WG::API::NET::Servers;

use Moo::Role;

our $VERSION = 'v0.8.3';

sub servers_info { 
    my ( $self, %params ) = @_;

    return $self->_request( 'get', 'servers/info', ['language', 'fields', 'game'], undef, %params ); 
}

1; # End of WG::API::NET::Servers

