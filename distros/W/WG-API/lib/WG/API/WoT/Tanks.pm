package WG::API::WoT::Tanks;

use Moo::Role;

our $VERSION = 'v0.8.3';

sub tanks_stats {
    my $self = shift;

    return $self->_request( 'get', 'tanks/stats', ['language', 'fields', 'access_token', 'account_id', 'tank_id', 'in_garage'], ['account_id'], @_ );
}

sub tanks_achievements {
    my $self = shift;

    return $self->_request( 'get', 'tanks/achievements', ['language', 'fields', 'access_token', 'account_id', 'tank_id', 'in_garage'], ['account_id'], @_ );
}

1; # End of WG::API::WoT::Tanks

