#!perl
use 5.14.1;
use warnings;
use HTTP::Status qw(HTTP_TOO_MANY_REQUESTS);
use HTTP::Response;
use Test::Fatal;
use Test::Spec;

BEGIN {
    my $time = 1_500_000_000;
    *CORE::GLOBAL::time = sub () {
        my ( $caller ) = caller();
        if($caller eq 'main' || $caller =~ /^Twitter::API/) {
            return $time++;
        } else {
            return CORE::time();
        }
    };
}

use Twitter::API;

sub new_client {
    my $limit = shift;
    my $exception_info;

    if(@_) {
        $exception_info = shift;
    } else {
        $exception_info = [ HTTP_TOO_MANY_REQUESTS, 'Rate Limit Exceeded',
            'x-rate-limit-reset' => time + 900 ];
    }

    my $remaining = $limit;

    my $user_agent = mock();
    $user_agent->stubs(request => sub {
        if(!defined($remaining) || $remaining-- > 0 ) {
            HTTP::Response->new(200, 'OK');
        } else {
            $remaining = $limit;

            my ( $code, $reason, %headers ) = @$exception_info;

            my $res = HTTP::Response->new($code, $reason);
            for my $name (keys %headers) {
                $res->header($name, $headers{$name});
            }
            $res
        }
    });

    return Twitter::API->new_with_traits(
        traits              => 'RateLimiting',
        consumer_key        => 'key',
        consumer_secret     => 'secret',
        access_token        => 'token',
        access_token_secret => 'token-secret',
        user_agent          => $user_agent,
    );
}

describe RateLimiting => sub {
    it 'should be unaffected if the rate limit is never hit' => sub {
        my $client = new_client();
        my $sleep = mock();

        $sleep->expects('ping')->exactly(0);

        $client->rate_limit_sleep_code(sub { $sleep->ping });

        $client->get('foo');
        $client->get('foo');
        $client->get('foo');
        $client->get('foo');

        pass;
    };

    it 'should invoke the sleep callback if the rate limit is hit' => sub {
        my $client = new_client(2);

        my $n_calls = 0;

        $client->rate_limit_sleep_code(sub { $n_calls++ });

        $client->get('foo');
        $client->get('foo');
        is $n_calls, 0, 'sleep should not be called before the 3rd request';
        $client->get('foo');
        is $n_calls, 1, 'sleep should be called exactly once after the 3rd request';
        $client->get('foo');
        is $n_calls, 1, 'the rate limit should have reset for the 4th request';
    };

    it 'should not intercept any other 4xx errors' => sub {
        my $client = new_client(2, [ 400, 'Unknown Error' ]);

        my $n_calls = 0;

        $client->rate_limit_sleep_code(sub { $n_calls++ });

        $client->get('foo');
        $client->get('foo');
        like exception {
            $client->get('foo');
        }, qr/Unknown Error/;

        is $n_calls, 0, 'sleep should not be called if a different 4xx error happens';
    };

    it 'should not intercept any 5xx errors' => sub {
        my $client = new_client(2, [ 500, 'Internal Server Error' ]);

        my $n_calls = 0;

        $client->rate_limit_sleep_code(sub { $n_calls++ });

        $client->get('foo');
        $client->get('foo');
        like exception {
            $client->get('foo');
        }, qr/Internal Server Error/;

        is $n_calls, 0, 'sleep should not be called if a 5xx error happens';
    };

    it 'should be called with the correct amount of time to sleep' => sub {
        my $reset_time = time + 900;

        my $client = new_client(2, [
            HTTP_TOO_MANY_REQUESTS, 'Rate Limit Exceeded',
            'x-rate-limit-reset' => $reset_time,
        ]);

        my $sleep_amount;

        $client->rate_limit_sleep_code(sub {
            ( $sleep_amount ) = @_;
        });

        $client->get('foo');
        $client->get('foo');
        my $next_time = time + 1;
        $client->get('foo');
        is $sleep_amount, ($reset_time - $next_time), 'sleep should be called with the correct time interval';
    };
};

runtests;
