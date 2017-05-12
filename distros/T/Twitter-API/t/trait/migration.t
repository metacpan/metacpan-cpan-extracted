#!perl
use 5.14.1;
use warnings;
use HTTP::Response;
use Test::Fatal;
use Test::Spec;
use Test::Warnings qw/warning/;
use URL::Encode qw/url_decode/;

use Twitter::API;

sub new_client {
    Twitter::API->new_with_traits(
        traits          => 'Migration',
        consumer_key    => 'key',
        consumer_secret => 'secret',
    );
}

# WWW::OAuth recommends WWW::Form::UrlEncoded::XS. If it isn't available, it
# falls back to WWW::Form::UrlEncoded::PP with a warning. Those warnings cause
# test failures, here. We'll force the fallback and bypass the potential
# warning. The tests shouldn't care whether the user has the recommended XS
# module or not.
$ENV{WWW_FORM_URLENCODED_PP} = 1;

context 'Net::Twitter migration' => sub {
    my $client;
    before each => sub {
        $client = new_client;
    };

    it 'dies with traits' => sub {
        like exception {
            Twitter::API->new(
                traits          => [ qw/Migration WrapResult/ ],
                consumer_key    => 'key',
                consumer_secret => 'secret',
            );
        }, qr/use new_with_traits/;
    };

    for ( [ authenticate => 'get_authentication_url' ],
          [ authorize    => 'get_authorization_url'  ] )
    {
        my ( $endpoint, $method ) = @$_;

        describe $method => sub {
            my $uri;
            before each => sub {
                $client->stubs(oauth_request_token => {
                    oauth_token              => 'token',
                    oauth_token_secret       => 'token-secret',
                    oauth_callback_confirmed => 'true',
                })->exactly(1);
                local $ENV{TWITTER_API_NO_MIGRATION_WARNINGS} = 1;
                $uri = $client->$method(callback => 'foo/bar');
            };

            it 'calls oauth_request_token' => sub {};
            it 'sets request_token' => sub {
                is $client->request_token, 'token';
            };
            it 'sets request_token_secret' => sub {
                is $client->request_token_secret, 'token-secret';
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
                    oauth_token => 'token',
                };
            };
        };
    }
    for my $method ( qw/
        get_authentication_url
        get_authorization_url
        request_access_token
    / )
    {
        describe $method => sub {
            it 'has migration warning' => sub {
                my $client = new_client;
                $client->stubs('request');
                like(
                    warning {
                        $client->$method(callback => 'nope');
                    }, qr/will be removed in a future release/
                );
            };
        };
    }
    describe get_access_token => sub {
        my @result;
        before each => sub {
            my $content = 'oauth_token=token&oauth_token_secret=token-secret'
                .'&user_id=666&screen_name=trump';
            $client->user_agent->stubs(request => sub {
                HTTP::Response->new(200, 'OK', [
                        content_type => 'application/x-www-form-urlencoded',
                        content_length => length $content,
                    ],
                    $content,
                );
            });
            $client->request_token('request-token');
            $client->request_token_secret('request-token-secret');
            local $ENV{TWITTER_API_NO_MIGRATION_WARNINGS} = 1;
            @result = $client->request_access_token(
                verifier => 'callback-verifier');
        };

        it 'returns (token, secret, screen_name, user_id)' => sub {
            is_deeply [ @result[0..3] ],
                      [ qw/token token-secret 666 trump/ ];
        };
        it 'sets access_token' => sub {
            is $client->access_token, 'token';
        };
        it 'sets access_token_secret' => sub {
            is $client->access_token_secret, 'token-secret';
        };
        it 'clears request_token' => sub {
            ok !$client->has_request_token;
        };
        it 'clears request_token_secret' => sub {
            ok !$client->has_request_token_secret;
        };
    };
    describe wrap_result => sub {
        before each => sub {
            $client = Twitter::API->new_with_traits(
                traits              => 'Migration',
                wrap_result         => 1,
                consumer_key        => 'key',
                consumer_secret     => 'secret',
                access_token        => 'token',
                access_token_secret => 'token-secret',
            );
            $client->stubs(send_request => 1);
            $client->stubs(inflate_response => sub {
                $_[1]->set_result({});
            });
            $client->access_token('token');
            $client->access_token_secret('token-secret');
        };

        it 'returns a context object' => sub {
            local $ENV{TWITTER_API_NO_MIGRATION_WARNINGS} = 1;
            my $r = $client->get('some/endpoint');
            ok( blessed $r && $r->isa('Twitter::API::Context'));
        };
        it 'has migration warning' => sub {
            like( warning { $client->get('some/endpoint') },
                qr/wrap_result is enabled/);
        };
    };
    describe ua => sub {
        it 'has migration warning' => sub {
            like warning { $client->ua }, qr/will be removed/;
        };
        it 'returns an HTTP::Thin' => sub {
            local $ENV{TWITTER_API_NO_MIGRATION_WARNINGS} = 1;
            my $ua = $client->ua;
            ok blessed $ua && $ua->isa('HTTP::Thin');
        };
    };
};

context 'with AppAuth' => sub {
    # token straight out of Twitter docs
    my $url_encoded_token = 'AAAA%2FAAA%3DAAAAAAAA';
    my $url_decoded_token = url_decode($url_encoded_token);

    my $client;
    before each => sub {
        $client = Twitter::API->new_with_traits(
            traits          => [ qw/Migration AppAuth/ ],
            consumer_key    => 'key',
            consumer_secret => 'secret',
        );
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

    describe request_access_token => sub {
        it 'client does not have an access_token before the call' => sub {
            ok !$client->has_access_token;
        };
        it 'sets access_token' => sub {
            local $ENV{TWITTER_API_NO_MIGRATION_WARNINGS} = 1;
            $client->request_access_token;
            is $client->access_token, $url_decoded_token;
        };
    };
};

runtests;
