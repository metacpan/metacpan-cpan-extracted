use strict;
use warnings;
use utf8;
use Test::More;
use Test::Flatten;
use Test::SharedFork;
use Test::Fake::HTTPD;
use JSON;

use WWW::Google::Cloud::Messaging;

sub new_gcm {
    WWW::Google::Cloud::Messaging->new(api_key => 'api_key', @_);
}

can_ok 'WWW::Google::Cloud::Messaging', 'build_request';

subtest 'required payload' => sub {
    eval { new_gcm->build_request };
    like $@, qr/Usage: \$gcm->build_request\(\\%payload\)/;
};

subtest 'payload must be hashref' => sub {
    for my $payload ('foo', [], undef) {
        eval { new_gcm->build_request($payload) };
        like $@, qr/Usage: \$gcm->build_request\(\\%payload\)/;
    }
};

subtest 'request correctly built' => sub {
    my $payload = { key1 => 1, key2 => 2, delay_while_idle => 2 };
    my $req = new_gcm->build_request($payload);
    is $req->method, 'POST';
    is $req->header('Authorization'), 'key=api_key';
    is $req->header('Content-Type'), 'application/json; charset=UTF-8';

    my $got_payload = decode_json $req->content;
    is $got_payload->{key1}, 1;
    is $got_payload->{key2}, 2;
    is $got_payload->{delay_while_idle}, JSON::true;
};

done_testing;
