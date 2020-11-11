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

    my %resp;

    if ( $uri eq '/json-api/cpanel' ) {
        %resp = _get_uapi_response($req);
    }
    else {
        %resp = _get_api1_response($req);
    }

    my $resp_obj = HTTP::Response->new(
        200, 'OK',
        [
            'Content-Type' => 'application/json',
        ],
        JSON::encode_json( \%resp ),
    );

    return $resp_obj;
}

sub _get_uapi_response {
    my ($req) = @_;

    my @ret_kv;

    my ($username) = $req->content() =~ m<cpanel_jsonapi_user=([^&]+)>;

    if ( $username =~ m<bad> ) {
        @ret_kv = (
            "data" => {
                "reason" => "User parameter is invalid or was not supplied",
                "result" => "0",
            },
            "type"  => "text",
            "error" => "User parameter is invalid or was not supplied",
        );
    }
    else {
        @ret_kv = (
            result => {
                status   => 1,
                metadata => { transformed => 1 },
                errors   => undef,
                warnings => undef,
                messages => undef,
                data     => _faux_data($req),
            },
        );

    }

    return @ret_kv;
}

sub _faux_data {
    my ($req) = @_;

    return {
        method  => $req->method(),
        uri     => $req->uri()->as_string(),
        headers => [ $req->flatten() ],
        content => $req->content(),
    };
}

sub _get_api1_response {
    my ($req) = @_;

    my $uri = $req->uri()->as_string();

    my $status = ( $uri =~ m<fail> ) ? 0 : 1;

    my %metadata = (
        version => 1,
        command => 'thecommand',
        result  => $status,
        reason  => "Status: $status",
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

    return (
        metadata => \%metadata,
        data     => _faux_data($req),
    );
}

1;
