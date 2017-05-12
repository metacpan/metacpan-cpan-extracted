#!perl
use 5.14.1;
use warnings;
use HTTP::Response;
use URL::Encode qw/url_decode/;
use Test::Spec;

use Twitter::API;

# token straight out of Twitter docs
my $url_encoded_token = 'AAAA%2FAAA%3DAAAAAAAA';
my $url_decoded_token = url_decode($url_encoded_token);

describe AppAuth => sub {
    my $client;
    before each => sub {
        $client = Twitter::API->new_with_traits(
            traits          => 'AppAuth',
            consumer_key    => 'key',
            consumer_secret => 'secret',
        );
    };
    describe oauth2_token => sub {
        before each => sub {
            my $content = '{"token_type":"bearer","access_token"'
                .':"'.$url_encoded_token.'"}';
            $client->user_agent->stubs(request => sub {
                HTTP::Response->new(200, 'OK', [
                        content_type   => 'application/json; charset=utf-8',
                        content_length => length $content,
                    ],
                    $content,
                );
            });
        };

        it 'uses Basic auth' => sub {
            my ( $r, $c ) = $client->oauth2_token;
            like $c->http_request->header('authorization'),
                qr/^Basic /;
        };
        it 'returns a url_decoded token' => sub {
            my $r = $client->oauth2_token;
            # Twitter sends it url_encoded, AppAuth decodes it
            is $r, $url_decoded_token;
        };
    };
    describe invalidate_token => sub {
        my $token;
        before each => sub {
            my $content = '{"access_token":"'.$url_encoded_token.'"}';
            $client->user_agent->stubs(request => sub {
                HTTP::Response->new(200, 'OK', [
                        content_type   => 'application/json; charset=utf-8',
                        content_length => length $content,
                    ],
                    $content,
                );
            });
        };

        it 'sends a url encoded token' => sub {
            my ( $r, $c ) = $client->invalidate_token($url_decoded_token);
            like $c->http_request->content,
                qr/access_token=\Q$url_encoded_token/;
        };

        it 'it returns the url_decoded token' => sub {
            my $r = $client->invalidate_token($url_decoded_token);
            is $r, $url_decoded_token;
        };
    };
    describe 'authenticated request' => sub {
        my $req;
        before each => sub {
            $client->user_agent->stubs(request => sub {
                HTTP::Response->new(200, 'OK',
                    [ content_type => 'application/json; charset=utf-8' ],
                    '{}'
                );
            });
            my ( undef, $c ) = $client->get('some/endpoint', {
                -token => $url_decoded_token,
            });
            $req = $c->http_request;
        };

        it 'adds Bearer authorization' => sub {
            like $req->header('authorization'),
                qr/Bearer \Q$url_encoded_token/;
        };
    };
};

runtests;
