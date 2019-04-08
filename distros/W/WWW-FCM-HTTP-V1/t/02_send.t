use strict;
use warnings;
use Test::More;
use Test::Fake::HTTPD;
use Test::Exception;
use JSON;
use HTTP::Status qw(:constants);

use WWW::FCM::HTTP::V1;

plan skip_all => 'Not supported on MSWin32' if $^O eq 'MSWin32';

my $dummy_api_key_json = '{
"type": "service_account",
"project_id": "test-project",
"private_key_id": "test_key_id",
"private_key": "-----BEGIN RSA PRIVATE KEY-----\nMIICXAIBAAKBgQCaE2qyAMVeCLiFdaX5BJeuLZLZUrRE8SMaPmzgI8/t9texQI1o\nQp8mXpY1emcZ8XI9aXliP3wHN5YKRENKtXsgdwevK3El8AjElZae9KSkhfcu34kj\nE3em5JzQVswfaY/tuql897ViaO5V2RLzCv/GEpQX8fd7vlo0AbGciugArwIDAQAB\nAoGAKxwdsVp33ryv7F+jpc48JncH7Jiwac3SlYg77Gb4yctURHscVby2TQUQIDx0\nVpTw8u/tD6lVqatK5up8rY2jul2LVu36UiGC3uewPnmdr3HAJEsit2fZo4XzSZkR\nGRWzs4E3U7VqRiQDCu4cJ52Va2ik7isLMOCh/zR11/QHo4kCQQDKRObJ6OsFSFVt\ntdBZl0zLEAtF6YW1lazPibeOA34GFmXmJP68I14uP5Ygk1ig/JugG5592o17kC69\niLY6pDEjAkEAwwEuXEsYFkgV/nfccVzgdN366hDUYOXMBGwFDX1A8ymoX8BbtgyS\nLdmcCN6uLB+aqdzMt2Y2V9uZe24ZCPj5BQJAdgGK0AOGkhdoV9B6FLrTv6jFmu0p\n6A3Bu3cyUrUw4iZRHts4jtTnjn3kfW7Zh1q5BMj4R56paoxs6IEJJ99BFwJAIgWQ\nuxV27FxDShRLZ5PWrU0VO8UX6JfvEk5uSz4xGLuJ3rrGxWpIDqvKp1mCdbxF1aDq\nLo0sqgNsMbaxs3kMqQJBAKRCOpnCS/QyZDzqgMcWOQYmrPqD3AzDUvfYLnOazsPM\nTrtipLksxq0k/mrCFnyId/SvAprUfwScE6Fc7HkA9Ac=\n-----END RSA PRIVATE KEY-----"
}';
my $fcm = WWW::FCM::HTTP::V1->new(api_url => 'api_url', api_key_json => $dummy_api_key_json);

sub test_send {
    my %specs = @_;
    my ($input, $expects, $expects_exception, $desc)
        = @specs{qw/input expects expects_exception desc/};

    subtest $desc => sub {
        my $access_token_httpd = run_http_server {
            return create_response(@$expects{qw/token_code token_data token_headers/});
        };

        $fcm->sender->token_url($access_token_httpd->endpoint);

        my $httpd = run_http_server {
            my $req = shift;
            my $params = decode_json +$req->content;
            is_deeply $params, $expects->{send_data};
            return create_response(@$expects{qw/code data headers/});
        };

        $fcm->api_url($httpd->endpoint);

        unless ($expects_exception) {
            lives_ok {
                $fcm->send($input);
            };
        }
        else {
            throws_ok {
                $fcm->send($input);
            } $expects_exception->{message};
        }
    };
}

sub create_response {
    my ($code, $data, $headers) = @_;
    my $content = ref $data ? encode_json($data) : $data;
    return [$code => [
        'Content-Length' => length($content),
        'Content-Type'   => 'application/json; charset=UTF-8',
        @{ $headers || [] },
    ], [$content]];
}

subtest 'required payload' => sub {
    eval { $fcm->send };
    like $@, qr/Usage: \$fcm->send\(\\%content\)/;
};

subtest 'payload must be hashref' => sub {
    for my $payload ('foo', [], undef) {
        eval { $fcm->send($payload) };
        like $@, qr/Usage: \$fcm->send\(\\%content\)/;
    }
};

test_send(
    desc  => 'send success',
    input => {
        message => {
            token => 'device_token01',
            notification => {
                body  => 'This is an FCM notification message!',
                title => 'FCM Message',
            },
        },
    },
    expects => {
        send_data => {
            message => {
                token => 'device_token01',
                notification => {
                    body  => 'This is an FCM notification message!',
                    title => 'FCM Message',
                },
            },
        },
        token_code => HTTP_OK,
        token_data => {
            access_token => "test_access_token",
        },
        code => HTTP_OK,
    },
);

test_send(
    desc  => 'unauthorized',
    input => {
        message => {
            token => 'device_token01',
            notification => {
                body  => 'This is an FCM notification message!',
                title => 'FCM Message',
            },
        },
    },
    expects => {
        send_data => {},
        token_code => HTTP_UNAUTHORIZED,
        code => HTTP_UNAUTHORIZED,
    },
    expects_exception => {
        code => HTTP_UNAUTHORIZED,
        message => '/Failed to get access token. 401 Unauthorized /',
    },
);

test_send(
    desc  => 'internal server error',
    input => {
        message => {
            token => 'device_token01',
            notification => {
                body  => 'This is an FCM notification message!',
                title => 'FCM Message',
            },
        },
    },
    expects => {
        send_data => {
            message => {
                token => 'device_token01',
                notification => {
                    body  => 'This is an FCM notification message!',
                    title => 'FCM Message',
                },
            },
        },
        token_code => HTTP_OK,
        token_data => {
            access_token => "test_access_token",
        },
        code => HTTP_INTERNAL_SERVER_ERROR,
        data => 'Cannot read response header: timeout',
    },
);

test_send(
    desc  => 'fcm error: INVALID_ARGUMENT',
    input => {
        message => {
            token => 'device_token01',
            notification => {
                body  => 'This is an FCM notification message!',
                title => 'FCM Message',
            },
        },
    },
    expects => {
        send_data => {
            message => {
                token => 'device_token01',
                notification => {
                    body  => 'This is an FCM notification message!',
                    title => 'FCM Message',
                },
            },
        },
        token_code => HTTP_OK,
        token_data => {
            access_token => "test_access_token",
        },
        code => HTTP_BAD_REQUEST,
        data => {
            error => {
                code => 400,
                message => "Invalid Argument.",
                status  => "BAD_REQUEST",
                details => [
                    {
                        '@type'   => "type.googleapis.com/google.firebase.fcm.v1.FcmError",
                        errorCode => "INVALID_ARGUMENT"
                    }
                ]
            }
        },
    },
);

done_testing;
