package WG::API::WoWs::Warships;

use Moo::Role;

our $VERSION = 'v0.8.1';

sub ships_stats {
    my $self = shift;

    $self->_request( 'get', 'ships/stats', ['language', 'fields', 'access_token', 'extra', 'account_id', 'ship_id', 'in_garage'], ['account_id'], $_[0] );

    return $self->status eq 'ok' ? $self->response : undef;
}

1; # End of WG::API::WoWs::Warships

