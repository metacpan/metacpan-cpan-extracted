#!perl
use 5.14.1;
use warnings;
use HTTP::Response;
use Ref::Util qw/is_ref/;
use Test::Fatal;
use Test::Spec;

use Twitter::API;

sub new_client {
    my $response = shift;

    my $user_agent = mock();
    $user_agent->stubs(request => sub {
        like $_[1]->headers->header('authorization'), qr/^OAuth\s/, 'The Authorization header should start with OAuth';

        my ( $code, $reason ) = is_ref($$response[0])
            ? @{ shift @$response // [ 999 => 'off the end' ] }
            : @{ $response };
        HTTP::Response->new($code, $reason);
    });

    return Twitter::API->new_with_traits(
        traits              => 'RetryOnError',
        consumer_key        => 'key',
        consumer_secret     => 'secret',
        access_token        => 'token',
        access_token_secret => 'token-secret',
        user_agent          => $user_agent,
        @_
    );
}

describe RetryOnError => sub {
    it 'dies after 5 retries' => sub {
        my $client = new_client([ 503 => 'Temporarily Unavailable' ]);
        my $retry = mock();
        $retry->expects('ping')->exactly(5);
        $client->retry_delay_code(sub { $retry->ping });
        like exception {
            $client->get('foo');
        }, qr/Temporarily Unavailable/;
    };
    it 'dies immediately on 404' => sub {
        my $client = new_client([ 404 => 'Not Found' ]);
        my $retry = mock();
        $retry->expects('ping')->exactly(0);
        $client->retry_delay_code(sub { $retry->ping });
        like exception {
            $client->get('foo');
        }, qr/Not Found/;
    };
    it 'dies no first perm error' => sub {
        my $client = new_client([
            [ 500 => 'Internal Server Error'   ],
            [ 503 => 'Temporarily Unavailable' ],
            [ 403 => 'Forbidden'               ],
        ]);
        my $retry = mock();
        $retry->expects('ping')->exactly(2);
        $client->retry_delay_code(sub { $retry->ping });
        like exception {
            $client->get('foo');
        }, qr/Forbidden/;
    };
    it 'succeeds after retry' => sub {
        my $client = new_client([
            [ 500 => 'Internal Server Error'   ],
            [ 503 => 'Temporarily Unavailable' ],
            [ 200 => 'OK'                      ],
        ]);
        my $retry = mock();
        $retry->expects('ping')->exactly(2);
        $client->retry_delay_code(sub { $retry->ping });
        is exception {
            $client->get('foo');
        }, undef;
    };
    it 'succeeds immediately on 200' => sub {
        my $client = new_client([ 200 => 'OK' ]);
        my $retry = mock();
        $retry->expects('ping')->exactly(0);
        $client->retry_delay_code(sub { $retry->ping });
        is exception {
            $client->get('foo');
        }, undef;
    };
    it 'has expected initial delay' => sub {
        my $client = new_client([
            [ 500 => 'Internal Server Error'   ],
            [ 200 => 'OK'                      ],
        ]);
        my $retry = mock();
        $retry->expects('ping')->with(0.25);
        $client->retry_delay_code(sub { $retry->ping(@_) });
        is exception {
            $client->get('foo');
        }, undef;
    };
    it 'delay doubles' => sub {
        my $client = new_client([
            [ 500 => 'Internal Server Error'   ],
            [ 500 => 'Internal Server Error'   ],
            [ 200 => 'OK'                      ],
        ]);
        my $expected_delay = 0.25;
        $client->retry_delay_code(sub {
            my $delay = shift;
            is $delay, $expected_delay;
            $expected_delay *= 2;
        });
        is exception { $client->get('foo') }, undef;
    };
};

runtests;
