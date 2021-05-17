#!/usr/bin/env perl
use 5.012;
use lib 't/lib';
use MyTest;
use Benchmark 'timethis';

my $pool = UniEvent::HTTP::Pool->new;
my $retr = 0;

my $req = UniEvent::HTTP::Request->new({
    uri => 'http://dev.crazypanda.ru:305/',
    timeout => 1,
    redirection_limit => 1,
    response_callback => sub {
        my ($request, $response, $err) = @_;
        say "err=$err";
        if ($err && ++$retr < 5) {
            $pool->request($request);
        }
        #$client1->request($request);
        #$request->cancel;
    },
});

$pool->request($req);

UE::Loop->default_loop->run;
