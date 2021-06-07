#!/usr/bin/env perl
use 5.012;
use warnings;
use XLog;
use lib 'blib/lib', 'blib/arch', 't/lib';
use Benchmark qw/timethis timethese/;
use MyTest;
use UniEvent::HTTP::Manager;

$SIG{PIPE} = 'IGNORE';
my $l = UE::Loop->default;

say "START $$";

my $t = new UE::Timer($l);
$t->start(1);

MyTest::run_server({
    server => {
        locations => [{host => 'localhost', port => 4555}],
        max_keepalive_requests => 10000,
    },
    min_servers    => 1,
    max_servers    => 1,
    #max_requests   => 100000,
    min_load       => 0.2,
    max_load       => 0.5,
    #min_spare_servers => 1,
    #max_spare_servers => 2,
    bind_model => UniEvent::HTTP::Manager::BIND_REUSE_PORT,
    #activity_timeout => 5,
    termination_timeout => 5,
    min_worker_ttl => 10,
    worker_model => UniEvent::HTTP::Manager::WORKER_THREAD,
    check_interval => 1,
}, $l);

say "END";