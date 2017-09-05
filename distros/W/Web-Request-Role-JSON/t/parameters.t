use strict;
use warnings;
use Test::More;
use HTTP::Request;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;
use Web::Request;
use Encode;
use JSON::MaybeXS qw(encode_json decode_json is_bool);
use utf8;

package Request;
use Moose;
extends "Web::Request";
with(
    'Web::Request::Role::JSON' => {
        content_type => 'application/json'
    }
);

sub default_encoding { return 'UTF-8' }

1;

package main;

# The fake app we use for testing
my $handler = builder {
    sub {
        my $env = shift;

        #        my $req  = $req_class->name->new_from_env($env);
        my $req  = Request->new_from_env($env);
        my $path = $env->{PATH_INFO};

        my $res;

        # json_response
        if ( $path eq '/get/utf8' ) {
            $res = $req->json_response( { value => 'töst' } );
        }

        return $res->finalize;
    };
};

# and finally the tests!
test_psgi(
    app    => $handler,
    client => sub {
        my $cb = shift;

        subtest 'json_response plain' => sub {
            my $res = $cb->( GET "http://localhost/get/utf8" );
            is( $res->code, 200, 'status' );
            is(
                $res->header('content-type'),
                'application/json',
                'content-type'
            );
            is( decode_utf8( $res->content ), '{"value":"töst"}', 'content' );
        };

    }
);

done_testing;
