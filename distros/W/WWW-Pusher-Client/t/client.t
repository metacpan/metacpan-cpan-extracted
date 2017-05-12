#! /usr/bin/perl

use strict;
use warnings;
use AnyEvent;
use Test::Spec;
use Test::Fatal;

BEGIN {
    unless (use_ok('WWW::Pusher::Client')) {
        plan skip_all => "Not running without PUSHER_KEY env var";
        exit 0;
    }
}

describe 'Pusher Client' => sub {
    my ($client);

    # These fake credentials are found in Pusher's online
    # documentation about authentication
    my %fake_args = (
        auth_key => '278d425bdf160c739803',
        secret => '7ad3773142a6692b25b8'
    );

    before each => sub {
        $client = WWW::Pusher::Client->new(%fake_args);
    };

    it 'should format the ws_url properly' => sub {
        like($client->ws_url, qr/ws\.pusherapp\.com.*app.*protocol.*client.*version/);
    };

    describe 'authentication' => sub {
        before each => sub {
            $client->_socket_id('1234.1234');
        };

        it 'should properly construct socket auth signatures' => sub {
            my $auth = $client->_socket_auth('private-foobar');
            is($auth, '58df8b0c36d6982b82c3ecf6b4662e34fe8c25bba48f5369f135bf843651c3a4');
        };

        it 'should submit an key:signature for private channel auth' => sub {
            my $private_channel = 'private-fake-channel';
            my $data = $client->_construct_private_auth_data($private_channel);

            is($data->{auth},
               '278d425bdf160c739803:910dc5795badbf230a7510131e786c906e2d5dfb7f209f27a0945373bcc46615');
            is($data->{channel}, $private_channel)
        };

        it 'should only submit the channel for public channels' => sub {
            my $public_channel = 'fake-public-channel';
            my $data = $client->_construct_private_auth_data($public_channel);
            ok(not exists $data->{auth});
            is($data->{channel}, $public_channel);
        };

    };

    describe 'forged signature exploit fix' => sub {
        my ($socket_id, $channel);

        it 'should reject invalid socket ids' => sub {
            my $invalid_id = 'invalid';
            like( exception { $client->_socket_id( $invalid_id ) }, qr/invalid/ );
        };

        it 'should reject invalid channel names' => sub {
            my $invalid_channel = 'bad channel %';
            like( exception { $client->channel( $invalid_channel ) }, qr/invalid/);
        };
    };
};

runtests;
