#!perl
use warnings;
use Test::Spec;

use Twitter::API;

describe invalidate_access_token => sub {
    my $client;
    before each => sub {
        $client = Twitter::API->new_with_traits(
            traits              => 'ApiMethods',
            consumer_key        => 'key',
            consumer_secret     => 'secret',
            access_token        => 'token',
            access_token_secret => 'token-secret',
        );
        $client->stubs(send_request => sub { return });
    };

    it 'inferrs token/secret' => sub {
        my $c = $client->invalidate_access_token;
        my $req = $c->http_request;
        my $params = do {
            my $uri = URI->new;
            $uri->query($req->decoded_content);
            +{ $uri->query_form };
        };
        ok $req->method eq 'POST'
        && $req->uri->path =~ m{/oauth/invalidate_token\.json$}
        && eq_hash($params, {
            access_token        => 'token',
            access_token_secret => 'token-secret',
        });
    };

    it 'accepts synthetic token/secret args' => sub {
        my $c = $client->invalidate_access_token({
            -token        => 'token',
            -token_secret => 'token-secret',
        });
        my $req = $c->http_request;
        my $params = do {
            my $uri = URI->new;
            $uri->query($req->decoded_content);
            +{ $uri->query_form };
        };
        ok $req->method eq 'POST'
        && $req->uri->path =~ m{/oauth/invalidate_token\.json$}
        && eq_hash($params, {
            access_token        => 'token',
            access_token_secret => 'token-secret',
        });
    };

    it 'accepts access_token/access_token_secret args' => sub {
        my $c = $client->invalidate_access_token({
            access_token        => 'token',
            access_token_secret => 'token-secret',
        });
        my $req = $c->http_request;
        my $params = do {
            my $uri = URI->new;
            $uri->query($req->decoded_content);
            +{ $uri->query_form };
        };
        ok $req->method eq 'POST'
        && $req->uri->path =~ m{/oauth/invalidate_token\.json$}
        && eq_hash($params, {
            access_token        => 'token',
            access_token_secret => 'token-secret',
        });
    };
};

runtests;
