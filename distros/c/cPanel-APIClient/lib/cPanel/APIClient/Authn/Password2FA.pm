package cPanel::APIClient::Authn::Password2FA;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use parent 'cPanel::APIClient::Authn';

use cPanel::APIClient::Utils::HTTPSession;

sub new {
    my ( $class, $username, $password, $tfa_token ) = @_;

    return bless {
        username => $username,
        password => $password,
        tfa_token => $tfa_token,
    }, $class;
}

sub needs_session { 1 }

sub get_login_request_pieces {
    my ($self) = @_;

    return cPanel::APIClient::Utils::HTTPSession::get_login_request_pieces(
        @{$self}{ 'username', 'password', 'tfa_token' },
    );
}

sub consume_session_response {
    my ( $self, $resp_obj ) = @_;

    $self->{'url_token'} = cPanel::APIClient::Utils::HTTPSession::parse_token($resp_obj);

    return $self;
}

sub get_url_path_prefix {
    my ($self) = @_;

    return $_[0]{'url_token'} || die 'Need security token first!';
}

1;
