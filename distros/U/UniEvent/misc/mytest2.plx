#!/usr/bin/perl
use 5.012;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Benchmark qw/timethis timethese/;
use Data::Dumper qw/Dumper/;
use UniEvent qw/:const addrinfo_hints inet_pton inet_ntop inet_ptos inet_stop/;
use Devel::Peek;
use B::Concise;
use Socket ':all';
use Time::HiRes qw/time/;

$SIG{PIPE} = 'IGNORE';

say "START $$";
my $l = UniEvent::Loop->default_loop;

my $client = new UniEvent::TCP;
$client->connect('localhost', 3000);
$client->connect_callback(sub {
    my ($client, $err) = @_;
    die "should not happen" unless $err; 
    $l->stop;
    #$client->reset;
    #rest();
});
$l->run;

rest();


sub rest {
    my $server = new UniEvent::TCP;
    $server->bind('localhost', 3000);
    $server->listen;

    $client->connect_callback(sub {
        say "SECOND CONNECTION: @_";
    });

    $client->connect('localhost', 3000);
    
    $l->run;
}

say "END";
