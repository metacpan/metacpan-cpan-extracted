#!/usr/bin/env perl
use 5.012;
use warnings;
use XLog;
use lib 'blib/lib', 'blib/arch';
use UniEvent::Signal;
use UniEvent::HTTP::Manager;

$SIG{PIPE} = 'IGNORE';

use Data::Dumper;

XLog::set_level(XLog::DEBUG, "UniEvent::HTTP::Manager");
#XLog::set_level(XLog::DEBUG, "UniEvent::HTTP");
XLog::set_logger(sub { say $_[0] });
XLog::set_format("%4.6t =%p/%T= %c[%L/%1M]%C %f:%l,%F(): %m");

say "START $$";

my $min_servers = 1;
my $max_servers = 10;
my $check_interval = 1;

my $mgr = UniEvent::HTTP::Manager->new({
    server => {
        locations => [
            {host => 'localhost', port => 4555, reuse_port => 1},
            {host => 'localhost', port => 4556, reuse_port => 0},
            {path => "mysock"},
            #{host => 'dev.crazypanda.ru', port => 4555},
        ],
        max_keepalive_requests => 200000,
    },
    min_servers    => $min_servers,
    max_servers    => $max_servers,
    #max_requests   => 100000,
    min_load       => 0.2,
    max_load       => 0.5,
    #min_spare_servers => 1,
    #max_spare_servers => 2,
    #activity_timeout => 5,
    termination_timeout => 5,
    min_worker_ttl => 10,
    #worker_model => UniEvent::HTTP::Manager::WORKER_THREAD,
    check_interval => $check_interval,
});

my $si = UE::Signal->watch(UE::Signal::SIGINT, sub { $mgr->stop }, $mgr->loop);
my $st = UE::Signal->watch(UE::Signal::SIGTERM, sub { $mgr->stop }, $mgr->loop);

#$mgr->request_callback(sub {
#    my $req = shift;
#    #select undef, undef, undef, 0.001;
#    #sleep 10;
#    $req->respond({
#        code => 200,
#        body => "epta",
#    });
#});

my $ttyin = UE::Tty->new(\*STDIN, $mgr->loop);
$ttyin->read_start;
$ttyin->read_callback(sub {
    my (undef, $str) = @_;
    chomp($str);
    say "TTIN $str";
    
    if ($str eq 'restart') {
        say "REST WORKS";
        $mgr->restart_workers();
        return;
    }
    
    $min_servers++ if $str eq 'min+';
    $min_servers-- if $str eq 'min-';
    $max_servers++ if $str eq 'max+';
    $max_servers-- if $str eq 'max-';
    
    $check_interval += 0.1 if $str eq 'ci+';
    $check_interval -= 0.1 if $str eq 'ci-';

    my ($ok, $err) = $mgr->reconfigure({
        min_servers    => $min_servers,
        max_servers    => $max_servers,
        check_interval => $check_interval,
    });
    say "RECONFIGURE ERROR: $err" unless $ok;
});

$mgr->spawn_callback(sub {
    say "SPAWN PERL";
    my $server = shift;
    
    $server->request_callback(sub {
        my $req = shift;
        #select undef, undef, undef, 0.001;
        #sleep 10;
        $req->respond({
            code => 200,
            body => "epta",
        });
    });
});

$mgr->run;

say "END";
