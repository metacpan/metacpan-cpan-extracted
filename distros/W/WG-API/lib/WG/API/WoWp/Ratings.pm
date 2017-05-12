package WG::API::WoWp::Ratings;

use Moo::Role;

our $VERSION = 'v0.8.1';

sub ratings_types {
    my $self = shift;

    $self->_request( 'get', 'ratings/types', ['language', 'fields'], undef, @_ );

    return $self->status eq 'ok' ? $self->response : undef;
}

sub ratings_accounts {
    my $self = shift;

    $self->_request( 'get', 'ratings/accounts', ['language', 'fields', 'type', 'date', 'account_id'], ['type', 'account_id'], @_ );

    return $self->status eq 'ok' ? $self->response : undef;
}

sub ratings_neighbors {
    my $self = shift;

    $self->_request( 'get', 'ratings/neighbors', ['language', 'fields', 'type', 'date', 'account_id', 'rank_field', 'limit'], ['type', 'account_id', 'rank_field'], @_ );

    return $self->status eq 'ok' ? $self->response : undef;
}

sub ratings_top {
    my $self = shift;

    $self->_request( 'get', 'ratings/top', ['language', 'fields', 'type', 'date', 'rank_field', 'limit'], ['type', 'rank_field'], @_ );

    return $self->status eq 'ok' ? $self->response : undef;
}

sub ratings_dates {
    my $self = shift;
    
    $self->_request( 'get', 'ratings/dates', ['language', 'fields', 'type', 'account_id'], ['type'], @_ );

    return $self->status eq 'ok' ? $self->response : undef;
}

1; # End of WG::API::WoWp::Rationgs

