use strict;
use warnings;
use Test::More;
use HTTP::Request;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;
use Web::Request;
use Plack::Middleware::PrettyException;

use utf8;

# Generate a temp request class based on Web::Request and W:R:Role::JSON
my $req_class = Moose::Meta::Class->create(
    'MyReq',
    superclasses => ['Web::Request'],
    roles        => ['Web::Request::Role::JWT'],
    methods      => {
        default_encoding => sub {'UTF-8'}
    }
);

# The fake app we use for testing
my $handler = builder {
    enable "Plack::Middleware::PrettyException";
    sub {
        my $env  = shift;
        my $req  = $req_class->name->new_from_env($env);
        my $path = $env->{PATH_INFO};

        my $res;

        my $method = $path;
        $method =~ s{/}{};

        my $data = $req->$method;

        return [ 200, [ 'Content-Type' => 'text/plain' ], [$data] ];
    };
};

# and finally the tests!
test_psgi(
    app    => $handler,
    client => sub {
        my $cb = shift;
        subtest 'get_jwt' => sub {
            my $req =
                HTTP::Request->new( GET => 'http://localhost/get_jwt', );
            my $res = $cb->($req);
            is( $res->code,    200, 'status 200' );
            is( $res->content, '',  'no token' );
        };

        subtest 'get_jwt_claims' => sub {
            my $req =
                HTTP::Request->new( GET => 'http://localhost/get_jwt_claims',
                );
            my $res = $cb->($req);
            is( $res->code,    200, 'status 200' );
            is( $res->content, '',  'no claims' );
        };

        subtest 'get_jwt_claim_sub' => sub {
            my $req =
                HTTP::Request->new(
                GET => 'http://localhost/get_jwt_claim_sub', );
            my $res = $cb->($req);
            is( $res->code,    200, 'status 200' );
            is( $res->content, '',  'no claim.sub' );
        };

        subtest 'get_jwt_claim_aud' => sub {
            my $req =
                HTTP::Request->new(
                GET => 'http://localhost/get_jwt_claim_aud', );
            my $res = $cb->($req);
            is( $res->code,    200, 'status 200' );
            is( $res->content, '',  'no claim.aud' );
        };

        subtest 'requires_jwt' => sub {
            my $req =
                HTTP::Request->new( GET => 'http://localhost/requires_jwt', );
            my $res = $cb->($req);
            is( $res->code, 401, 'http status 401' );
        };

        subtest 'requires_jwt_claims' => sub {
            my $req =
                HTTP::Request->new(
                GET => 'http://localhost/requires_jwt_claims', );
            my $res = $cb->($req);
            is( $res->code, 401, 'http status 401' );
        };

        subtest 'requires_jwt_claim_sub' => sub {
            my $req =
                HTTP::Request->new(
                GET => 'http://localhost/requires_jwt_claim_sub', );
            my $res = $cb->($req);
            is( $res->code, 401, 'http status 401' );
        };

    }
);

done_testing;
