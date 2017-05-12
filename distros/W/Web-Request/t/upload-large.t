#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;
use Web::Request;

my $file = "t/data/baybridge.jpg";

my @backends = qw( Server MockHTTP );
sub flip_backend { $Plack::Test::Impl = shift @backends }

local $ENV{PLACK_SERVER} = "HTTP::Server::PSGI";

my $app = sub {
    my $req = Web::Request->new_from_env(shift);
    is $req->uploads->{image}->size, -s $file;
    is $req->uploads->{image}->content_type, 'image/jpeg';
    is $req->uploads->{image}->basename, 'baybridge.jpg';
    $req->new_response(status => 200)->finalize;
};

test_psgi $app, sub {
    my $cb = shift;
    $cb->(POST "/", Content_Type => 'form-data', Content => [
             image => [ $file ],
         ]);
} while flip_backend;

done_testing;

