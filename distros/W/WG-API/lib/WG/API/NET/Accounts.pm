package WG::API::NET::Accounts;

use Moo::Role;

our $VERSION = 'v0.8.1';

sub accounts_list {
    my $self = shift;

    $self->_request( 'get', 'account/list', ['fields', 'game', 'type', 'search', 'limit'], undef, @_ );
    
    return $self->status eq 'ok' ? $self->response : undef;
}

sub account_info {
    my ( $self, %params ) = @_;

    $self->_request( 'get', 'account/info', ['fields', 'access_token', 'account_id'], ['account_id'], %params );
    
    return $self->status eq 'ok' &&  $self->response->{ $params{ 'account_id' } } ? $self->response->{ $params{ 'account_id' } } : undef;
}

1; # End of WG::API::NET::Accounts 

