package MockCpsrvd::cpanel;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;
use autodie;

use parent qw( MockCpsrvd );

use HTTP::Response ();
use JSON           ();

sub _get_response {
    my ( $self, $req ) = @_;

    my ( $status, %metadata, @errors, @warnings, @messages );

    my $uri = $req->uri()->as_string();

    $status = ( $uri =~ m<fail> ) ? 0 : 1;

    if ( $uri =~ m<errors> ) {
        push @errors, 'err1', 'err2';
    }

    if ( $uri =~ m<warnings> ) {
        push @warnings, 'warn1', 'warn2';
    }

    if ( $uri =~ m<messages> ) {
        push @messages, 'message1', 'message2';
    }

    my %resp = (
        status   => $status,
        metadata => \%metadata,
        errors   => \@errors,
        warnings => \@warnings,
        messages => \@messages,
        data     => {
            method  => $req->method(),
            uri     => $req->uri()->as_string(),
            headers => [ $req->flatten() ],
            content => $req->content(),
        },
    );

    my $resp = HTTP::Response->new(
        200, 'OK',
        [
            'Content-Type' => 'application/json',
        ],
        JSON::encode_json( \%resp ),
    );

    return $resp;
}

1;
