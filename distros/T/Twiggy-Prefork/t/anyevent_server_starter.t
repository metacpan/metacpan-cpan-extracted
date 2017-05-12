use strict;
use Test::More;
use Test::Requires qw(Server::Starter);
use Test::TCP;
use LWP::UserAgent;

test_tcp(
    server => sub {
        my $port = shift;

        Server::Starter::start_server(
            exec => [ $^X, '-MPlack::Loader', '-e',
                q|Plack::Loader->load('Twiggy::Prefork', host => '127.0.0.1')->run(sub { [ '200', ['Content-Type' => 'text/plain'], [ 'Hello, Twiggy!' ] ] })| ],
            port => [ $port ]
        );
        exit 1;
    },
    client => sub {
        my $port = shift;

        # XXX LWP is implied by plack
        my $ua = LWP::UserAgent->new();
        my $res = $ua->get("http://127.0.0.1:$port/");
        ok $res->is_success, "request ok";
        is $res->content, "Hello, Twiggy!";
    }
);

done_testing;
