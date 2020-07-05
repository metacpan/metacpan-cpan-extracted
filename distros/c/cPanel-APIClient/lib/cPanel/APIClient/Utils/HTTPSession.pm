package cPanel::APIClient::Utils::HTTPSession;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use cPanel::APIClient::Utils::HTTPRequest ();

sub get_login_request_pieces {
    my ( $username, $password, $tfa_token ) = @_;

    my %payload = (
        user       => $username,
        pass       => $password,
        login_only => 1,
    );

    $payload{'tfa_token'} = $tfa_token if $tfa_token;

    return (
        'POST',
        '/login',
        cPanel::APIClient::Utils::HTTPRequest::encode_form(\%payload),
    );
}

sub parse_token {
    my ($response_obj) = @_;

    my $loc = $response_obj->header('location') || do {
        die "No “Location” header given: " . $response_obj->as_string();
    };

    $loc =~ m<\A(/[^/]+)> or do {
        die "Unrecognized “Location” header: $loc";
    };

    return $1;
}

1;
