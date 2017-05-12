package WG::API::NET::Clans;

use Moo::Role;

our $VERSION = 'v0.8.1';

sub clans_list {
    my ( $self, $params ) = @_;

    $self->_request( 'get', 'clans/list', ['language', 'fields', 'search', 'orded_by', 'limit', 'page_no' ], undef, $params );

    return $self->status eq 'ok' ? $self->response : undef;
}

sub clans_info {
    my ( $self, $params ) = @_;

    $self->_request( 'get', 'clans/info', ['language', 'fields', 'access_token', 'clan_id'], ['clan_id'], $params );

    return $self->status eq 'ok' ? $self->response : undef; 
}

sub clans_membersinfo {
    my ( $self, $params ) = @_;

    $self->_request( 'get', 'clans/membersinfo', ['language', 'fields', 'account_id'], ['account_id'], $params );

    return $self->status eq 'ok' ? $self->response : undef;
}

sub clans_glossary {
    my ( $self, $params ) = @_;

    $self->_request( 'get', 'clans/glossary', ['language', 'fields'], undef, $params );

    return $self->status eq 'ok' ? $self->response : undef;
}

sub clans_messageboard {
    my ( $self, %params ) = @_;

    $self->_request( 'get', 'clans/mesageboard', ['language', 'fields', 'access_token'], ['access_token'], %params );

    return $self->status eq 'ok' ? $self->response : undef;
}

1; # End of WG::API::NET::Clans

