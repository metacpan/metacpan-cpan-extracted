package WG::API::WoT::Tanks;

use Moo::Role;

our $VERSION = 'v0.8.1';

sub tanks_stats {
    my $self = shift;

    $self->_request( 'get', 'tanks/stats', ['language', 'fields', 'access_token', 'account_id', 'tank_id', 'in_garage'], ['account_id'], @_ );

    return $self->status eq 'ok' ? $self->response : undef ;
}

sub tanks_achievements {
    my $self = shift;

    $self->_request( 'get', 'tanks/achievements', ['language', 'fields', 'access_token', 'account_id', 'tank_id', 'in_garage'], ['account_id'], @_ );

    return $self->status eq 'ok' ? $self->response : undef ;
}

1; # End of WG::API::WoT::Tanks

