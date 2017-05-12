#!perl
use 5.14.1;
use warnings;
use HTTP::Response;
use Test::Spec;

use Twitter::API;

sub new_client {
    Twitter::API->new(
        consumer_key    => 'key',
        consumer_secret => 'secret',
    );
}

my $token = 'Z6eEdO8MOmk394WozF5oKyuAv855l4Mlqo7hhlSLik';
my $secret = 'Kd75W4OQfb2oJTV0vzGzeXftVAwgMnEK9MumzYcM';

describe oauth => sub {
    my $client;
    before each => sub { $client = new_client };

    describe 'authentication urls' => sub {
        for ( [ authenticate => 'oauth_authentication_url' ],
              [ authorize    => 'oauth_authorization_url'  ] )
        {
            my ( $endpoint, $method ) = @$_;

            describe $method => sub {
                my $uri;
                before each => sub {
                    $uri = $client->$method(
                        oauth_token => $token,
                        force_login => 'true',
                        screen_name => 'bogus',
                    );
                };
                it 'has correct scheme' => sub {
                    is($uri->scheme, 'https');
                };
                it 'has correct host '  => sub {
                    is($uri->host, 'api.twitter.com');
                };
                it 'has correct path'   => sub {
                    is($uri->path, "/oauth/$endpoint");
                };
                it 'has correct query' => sub {
                    is_deeply { $uri->query_form }, {
                        oauth_token => $token,
                        force_login => 'true',
                        screen_name => 'bogus',
                    };
                };
            };
        }
    };
    describe oauth_request_token => sub {
        before each => sub {
            my $content = "oauth_token=$token&oauth_token_secret=$secret"
                ."&oauth_callback_confirmed=true";
            $client->user_agent->stubs(request => sub {
                HTTP::Response->new(200, 'OK', [
                        content_type => 'application/x-www-form-urlencoded',
                        content_length => length $content,
                    ],
                    $content,
                );
            });
        };

        it 'has valid authorization header' => sub {
            my ( $r, $c ) = $client->oauth_request_token;
            like $c->http_request->header('authorization'), qr/
                OAuth\s+
                oauth_callback="oob",\s+
                oauth_consumer_key="key",\s+
                oauth_nonce="[^"]+",\s+
                oauth_signature="[^"]+",\s+
                oauth_signature_method="HMAC-SHA1",\s+
                oauth_timestamp="\d+",\s+
                oauth_version="1.0"
            /x;
        };

        it 'returns a hashref with oauth_token/secret' => sub {
            my $r = $client->oauth_request_token;
            is_deeply $r, {
                oauth_token              => $token,
                oauth_token_secret       => $secret,
                oauth_callback_confirmed => 'true',
            };
        };
    };

    describe oauth_access_token => sub {
        before each => sub {
            # from the Twitter docs
            my $content = 'oauth_token=6253282-eWudHldSbIaelX7swmsiHImEL4Kinw'
                .'aGloHANdrY&oauth_token_secret=2EEfA6BG3ly3sR3RjE0IBSnlQu4Zr'
                .'UzPiYKmrkVU&user_id=6253282&screen_name=twitterapi';
            $client->user_agent->stubs(request => sub {
                HTTP::Response->new(200, 'OK', [
                        content_type => 'application/x-www-form-urlencoded',
                        content_length => length $content,
                    ],
                    $content,
                );
            });
        };

        it 'has a valid autorization header' => sub {
            my ( $r, $c ) = $client->oauth_access_token(
                token        => 'request-token',
                token_secret => 'request-token-secret',
                verifier     => 'verifier',
            );
            like $c->http_request->header('authorization'), qr/
                OAuth\s+
                oauth_consumer_key="key",\s+
                oauth_nonce="[^"]+",\s+
                oauth_signature="[^"]+",\s+
                oauth_signature_method="HMAC-SHA1",\s+
                oauth_timestamp="\d+",\s+
                oauth_token="request-token",\s+
                oauth_verifier="verifier",\s+
                oauth_version="1.0"
            /x;
        };
        it 'returns  a hashref with oauth_token/secret' => sub {
            my $r = $client->oauth_access_token(
                token        => 'request-token',
                token_secret => 'request-token-secret',
                verifier     => 'verifier',
            );
            is $$r{user_id}, 6253282;
            is $$r{screen_name}, 'twitterapi';
            like $$r{oauth_token}, qr/^6253282-eWudHldSb/;
            like $$r{oauth_token_secret}, qr/^2EEfA6BG3l/;
        };
        describe xauth => sub {
            it 'has a valid authorization header' => sub {
                my ( $r, $c ) = $client->xauth('alice', 'rabbit');
                like $c->http_request->header('authorization'), qr/
                    OAuth\s+
                    oauth_consumer_key="key",\s+
                    oauth_nonce="[^"]+",\s+
                    oauth_signature="[^"]+",\s+
                    oauth_signature_method="HMAC-SHA1",\s+
                    oauth_timestamp="\d+",\s+
                    oauth_version="1.0"
                /x;
            };
            it 'has required args' => sub {
                my ( $r, $c ) = $client->xauth('alice', 'rabbit');
                my $args = URL::Encode::url_params_mixed(
                    $c->http_request->content);
                is_deeply [ sort keys %$args ],
                    [ qw/x_auth_mode x_auth_password x_auth_username/ ];
            };
            it 'returns a hashref with oauth_token/secret' => sub {
                my $r = $client->xauth('foo@bar.baz', 'SeCrEt');
                is_deeply [ sort keys %$r ],
                    [ qw/oauth_token oauth_token_secret screen_name user_id/ ];
            };
        };
    };
};

runtests;
