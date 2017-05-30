package WG::API::WoWs::Warships;

use Moo::Role;

our $VERSION = 'v0.8.3';

sub ships_stats {
    my $self = shift;

    return $self->_request( 'get', 'ships/stats', ['language', 'fields', 'access_token', 'extra', 'account_id', 'ship_id', 'in_garage'], ['account_id'], @_ );
}

1; # End of WG::API::WoWs::Warships

