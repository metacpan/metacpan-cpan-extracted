use strict;
use warnings;
use Test::More;
use Test::SharedFork;
use Test::Fake::HTTPD;
use JSON;

use WWW::FCM::HTTP;
use WWW::FCM::HTTP::Constants;

plan skip_all => 'THIS TEST IS NOT SUPPORTED IN YOUR OS' if $^O eq 'MSWin32';

sub new_fcm {
    WWW::FCM::HTTP->new(api_key => 'api_key', @_);
}

sub get_request_data {
    my $req = shift;
    decode_json +$req->content;
}

sub create_response {
    my ($code, $data, $headers) = @_;
    my $content = eval { encode_json $data } || $data;
    return [$code => [
        'Content-Length' => length($content),
        'Content-Type'   => 'application/json; charset=UTF-8',
        @{ $headers || [] },
    ], [$content]];
}

sub test_send {
    my %specs = @_;
    my ($input, $expects, $desc) = @specs{qw/input expects desc/};

    subtest $desc => sub {
        my $fcm   = new_fcm();
        my $httpd = run_http_server {
            my $req    = shift;
            my $params = get_request_data($req);
            is_deeply $params, $input;

            is $req->header('Content-Type'), 'application/json; charset=UTF-8';
            is $req->header('Authorization'), sprintf 'key=%s', $fcm->api_key;

            return create_response(@$expects{qw/code data headers/});
        };

        $fcm->api_url($httpd->endpoint);
        my $res = $fcm->send($input);

        $expects->{data} = { error => $expects->{data} } unless ref $expects->{data};
        is $res->is_success,    $res->http_response->is_success;
        is $res->error,         $expects->{data}{error};
        is $res->success,       $expects->{data}{success};
        is $res->failure,       $expects->{data}{failure};
        is $res->canonical_ids, $expects->{data}{canonical_ids};
        is $res->multicast_id,  $expects->{data}{multicast_id};
        is $res->message_id,    $expects->{data}{message_id};

        isa_ok $res->http_response, 'HTTP::Response';
        is $res->status_line,   $res->http_response->status_line;

        return if $expects->{data}{error};
        return if $expects->{data}{message_id};

        my $results = $res->results;
        isa_ok $results, 'WWW::FCM::HTTP::Response::ResultSet';

        my $expects_results = $expects->{data}{results};
        my $sent_reg_ids    = $input->{registration_ids} || [];
        while (my $result = $results->next) {
            isa_ok $result, 'WWW::FCM::HTTP::Response::Result';

            my $expects_result = shift @$expects_results;
            is $result->is_success,       $expects_result->{error} ? 0 : 1;
            is $result->error,            $expects_result->{error};
            is $result->has_canonical_id, $expects_result->{registration_id} ? 1 : 0;
            is $result->registration_id,  $expects_result->{registration_id};
            is $result->message_id,       $expects_result->{message_id};
            is $result->sent_reg_id,      shift @$sent_reg_ids;
        }
    };
}

subtest 'required payload' => sub {
    eval { new_fcm->send };
    like $@, qr/Usage: \$fcm->send\(\\%payload\)/;
};

subtest 'payload must be hashref' => sub {
    for my $payload ('foo', [], undef) {
        eval { new_fcm->send($payload) };
        like $@, qr/Usage: \$fcm->send\(\\%payload\)/;
    }
};

test_send(
    desc  => 'send a message',
    input => {
        send_data => {
            registration_ids => [qw/foo/],
            collapse_key     => 'collapse_key',
            data             => {
                title => 'title',
                body  => 'body',
            },
        },
    },
    expects => {
        code => 200,
        data => {
            success       => 1,
            failure       => 0,
            canonical_ids => 0,
            multicast_id  => 12345,
            results       => [
                { message_id => 56789 },
            ],
        },
    },
);

test_send(
    desc  => 'send multicast',
    input => {
        send_data => {
            registration_ids => [qw/foo bar/],
            collapse_key     => 'collapse_key',
            data             => {
                title => 'title',
                body  => 'body',
            },
        },
    },
    expects => {
        code => 200,
        data => {
            success       => 1,
            failure       => 0,
            canonical_ids => 0,
            multicast_id  => 12345,
            results       => [
                { message_id => 56789 },
                { message_id => 67890 },
            ],
        },
    },
);

test_send(
    desc  => 'return error',
    input => {
        send_data => {},
    },
    expects => {
        code    => 400,
        data    => qq{Missing "registration_ids" field\n},
        headers => [
            'Content-Type' => 'text/plain; charset=UTF-8',
        ],
    },
);

test_send(
    desc  => 'multicast mixied success / error response',
    input => {
        send_data => {
            registration_ids => [qw/foo bar/],
            collapse_key     => 'collapse_key',
            data             => {
                title => 'title',
                body  => 'body',
            },
        },
    },
    expects => {
        code => 200,
        data => {
            success       => 1,
            failure       => 1,
            canonical_ids => 0,
            multicast_id  => 12345,
            results       => [
                { message_id => 56789 },
                { error => 'InvalidRegistration' },
            ],
        },
    },
);

test_send(
    desc  => 'return with registration_id',
    input => {
        send_data => {
            registration_ids => [qw/foo/],
            collapse_key     => 'collapse_key',
            data             => {
                title => 'title',
                body  => 'body',
            },
        },
    },
    expects => {
        code => 200,
        data => {
            success       => 1,
            failure       => 0,
            canonical_ids => 0,
            multicast_id  => 12345,
            results       => [
                { message_id => 56789, registration_id => 'baz' },
            ],
        },
    },
);

test_send(
    desc  => 'topic message',
    input => {
        send_data => {
            to   => 'topic/all',
            data => {
                title => 'title',
                body  => 'body',
            },
        },
    },
    expects => {
        code => 200,
        data => {
            message_id => 12345,
        },
    },
);

done_testing;
