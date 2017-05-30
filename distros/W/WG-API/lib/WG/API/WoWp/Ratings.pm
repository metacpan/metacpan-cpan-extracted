package WG::API::WoWp::Ratings;

use Moo::Role;

our $VERSION = 'v0.8.3';

sub ratings_types {
    my $self = shift;

    return $self->_request( 'get', 'ratings/types', ['language', 'fields'], undef, @_ );
}

sub ratings_accounts {
    my $self = shift;

    return $self->_request( 'get', 'ratings/accounts', ['language', 'fields', 'type', 'date', 'account_id'], ['type', 'account_id'], @_ );
}

sub ratings_neighbors {
    my $self = shift;

    return $self->_request( 'get', 'ratings/neighbors', ['language', 'fields', 'type', 'date', 'account_id', 'rank_field', 'limit'], ['type', 'account_id', 'rank_field'], @_ );
}

sub ratings_top {
    my $self = shift;

    return $self->_request( 'get', 'ratings/top', ['language', 'fields', 'type', 'date', 'rank_field', 'limit'], ['type', 'rank_field'], @_ );
}

sub ratings_dates {
    my $self = shift;
    
    return $self->_request( 'get', 'ratings/dates', ['language', 'fields', 'type', 'account_id'], ['type'], @_ );
}

1; # End of WG::API::WoWp::Rationgs

