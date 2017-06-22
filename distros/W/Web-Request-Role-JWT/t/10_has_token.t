use strict;
use warnings;
use Test::More;
use HTTP::Request;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;
use Web::Request;

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
    sub {
        my $env = shift;
        $env->{'psgix.token'}  = 'fake.token';
        $env->{'psgix.claims'} = {
            sub => 'Homer',
            aud => 'SpringfieldPowerPlant',
        };
        my $req  = $req_class->name->new_from_env($env);
        my $path = $env->{PATH_INFO};

        my $res;

        my $method = $path;
        $method =~ s{/}{};

        my $data = $req->$method;
        if ( ref($data) eq 'HASH' ) {
            $data =
                join( ';', map { $_ . '=' . $data->{$_} } sort keys %$data );
        }

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
            is( $res->code,    200,          'status 200' );
            is( $res->content, 'fake.token', 'token' );
        };

        subtest 'get_jwt_claims' => sub {
            my $req =
                HTTP::Request->new( GET => 'http://localhost/get_jwt_claims',
                );
            my $res = $cb->($req);
            is( $res->code, 200, 'status 200' );
            is( $res->content,
                'aud=SpringfieldPowerPlant;sub=Homer',
                'claims (as string)'
            );
        };

        subtest 'get_jwt_claim_sub' => sub {
            my $req =
                HTTP::Request->new(
                GET => 'http://localhost/get_jwt_claim_sub', );
            my $res = $cb->($req);
            is( $res->code,    200,     'status 200' );
            is( $res->content, 'Homer', 'claim.sub' );
        };

        subtest 'get_jwt_claim_aud' => sub {
            my $req =
                HTTP::Request->new(
                GET => 'http://localhost/get_jwt_claim_aud', );
            my $res = $cb->($req);
            is( $res->code, 200, 'status 200' );
            is( $res->content, 'SpringfieldPowerPlant', 'claim.aud' );
        };

        subtest 'requires_jwt' => sub {
            my $req =
                HTTP::Request->new( GET => 'http://localhost/requires_jwt', );
            my $res = $cb->($req);
            is( $res->code,    200,          'http status 200' );
            is( $res->content, 'fake.token', 'token' );
        };

        subtest 'requires_jwt_claims' => sub {
            my $req =
                HTTP::Request->new(
                GET => 'http://localhost/requires_jwt_claims', );
            my $res = $cb->($req);
            is( $res->code, 200, 'http status 200' );
            is( $res->content,
                'aud=SpringfieldPowerPlant;sub=Homer',
                'claims (as string)'
            );
        };

        subtest 'requires_jwt_claim_sub' => sub {
            my $req =
                HTTP::Request->new(
                GET => 'http://localhost/requires_jwt_claim_sub', );
            my $res = $cb->($req);
            is( $res->code,    200,     'http status 200' );
            is( $res->content, 'Homer', 'claim.sub' );
        };
    }
);

done_testing;
