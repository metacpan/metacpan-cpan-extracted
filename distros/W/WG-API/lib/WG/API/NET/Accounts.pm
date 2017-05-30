package WG::API::NET::Accounts;

use Moo::Role;

our $VERSION = 'v0.8.3';

sub accounts_list {
    my $self = shift;

    return $self->_request( 'get', 'account/list', ['fields', 'game', 'type', 'search', 'limit'], ['search'], @_ );
}

sub account_info {
    my ( $self, %params ) = @_;

    return $self->_request( 'get', 'account/info', ['fields', 'access_token', 'account_id'], ['account_id'], %params );
}

1; # End of WG::API::NET::Accounts 

