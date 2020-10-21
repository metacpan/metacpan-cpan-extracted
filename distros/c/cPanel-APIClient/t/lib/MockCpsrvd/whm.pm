package MockCpsrvd::whm;

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

    my $uri = $req->uri()->as_string();

    my $status = ( $uri =~ m<fail> ) ? 0 : 1;

    my %metadata = (
        version => 1,
        command => 'thecommand',
        result => $status,
        reason => "Status: $status",
    );

    if ( $uri =~ m<warnings1> ) {
        push @{ $metadata{'output'}{'warnings'} }, 'warn1', 'warn2';
    }
    if ( $uri =~ m<warnings2> ) {
        $metadata{'output'}{'warnings'} = "warn1\nwarn2";
    }

    if ( $uri =~ m<messages1> ) {
        push @{ $metadata{'output'}{'messages'} }, 'message1', 'message2';
    }
    if ( $uri =~ m<messages2> ) {
        $metadata{'output'}{'messages'} = "message1\nmessage2";
    }

    my %resp = (
        metadata => \%metadata,
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
