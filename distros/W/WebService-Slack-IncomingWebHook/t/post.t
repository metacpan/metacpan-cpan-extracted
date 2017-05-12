use strict;
use warnings;

use Test::Exception;
use Test::More;
use Test::TCP;

use Capture::Tiny qw( capture_stderr );
use JSON;
use HTTP::Server::PSGI;
use Plack::Request;
use WebService::Slack::IncomingWebHook;

my $json = JSON->new->utf8;
my $app_server = Test::TCP->new(
    code => sub {
        my $port = shift;
        my $server = HTTP::Server::PSGI->new(
            host => '127.0.0.1',
            port => $port,
        );

        $server->run(sub {
            my $env = shift;
            my $req = Plack::Request->new($env);
            my $params = $json->decode($req->content);
            my $channel = $params->{channel};

            if (
                !$channel ||
                $channel !~ m{\A[@#].+}
            ) {
                return [500, ['Content-Type' => 'text/html'], ['Invalid channel specified']];
            }
            return [200, ['Content-Type' => 'text/html'], ['ok']];
        });
    }
);

my $host = sprintf('http://127.0.0.1:%d/', $app_server->port);

subtest 'no webhook' => sub {
    throws_ok { capture_stderr(sub {
        WebService::Slack::IncomingWebHook->new();
    }) } qr{\Arequired webhook url};
};

subtest 'no chennel' => sub {
    like capture_stderr(sub {
        my $client = WebService::Slack::IncomingWebHook->new(webhook_url => $host);
        $client->post(text => 'hoge');
    }) => qr{\Apost failed: Invalid channel specified};

    like capture_stderr(sub {
        my $client = WebService::Slack::IncomingWebHook->new(webhook_url => $host);
        $client->post(channel => '', text => 'hoge');
    }) => qr{\Apost failed: Invalid channel specified};

    like capture_stderr(sub {
        my $client = WebService::Slack::IncomingWebHook->new(webhook_url => $host, channel => '');
        $client->post(text => 'hoge');
    }) => qr{\Apost failed: Invalid channel specified};
};

subtest 'invalid chennel' => sub {
    like capture_stderr(sub {
        my $client = WebService::Slack::IncomingWebHook->new(webhook_url => $host);
        $client->post(channel => 'channel', text => 'hoge');
    }) => qr{\Apost failed: Invalid channel specified};

    like capture_stderr(sub {
        my $client = WebService::Slack::IncomingWebHook->new(webhook_url => $host, channel => 'channel');
        $client->post(text => 'hoge');
    }) => qr{\Apost failed: Invalid channel specified};
};

done_testing;
