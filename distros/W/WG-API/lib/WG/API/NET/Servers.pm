package WG::API::NET::Servers;

use Moo::Role;

our $VERSION = 'v0.8.1';

sub servers_info { 
    my ( $self, %params ) = @_;

    $self->_request( 'get', 'servers/info', ['language', 'fields', 'game'], undef, %params ); 
    
    return $self->status eq 'ok' ? 
        $params{ 'game' } ? $self->response->{ $params{ 'game' } } : $self->response 
        : undef;
}

1; # End of WG::API::NET::Servers

