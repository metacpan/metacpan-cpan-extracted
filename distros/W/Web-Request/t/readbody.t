#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use Try::Tiny;
use Web::Request;

{
    try {
        my $data = 'a';
        open my $input, "<", \$data;
        my $req = Web::Request->new_from_env({
            'psgi.input'   => $input,
            CONTENT_LENGTH => 3,
            CONTENT_TYPE   => 'application/octet-stream'
        });
        $req->body_parameters;
    } catch {
        like $_, qr/Bad Content-Length/;
    }
}

done_testing;
