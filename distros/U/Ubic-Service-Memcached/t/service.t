#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Ubic::Service::Memcached;
use Cache::Memcached;

plan skip_all => 'memcached is not installed' unless -e '/usr/bin/memcached';
plan tests => 7;

my $port = 1358; # TODO - select any free port

# tests with verbose=2

sub xsystem {
    local $! = local $? = 0;
    return if system(@_) == 0;

    my @msg;
    if ($!) {
        push @msg, "error ".int($!)." '$!'";
    }
    if ($? > 0) {
        push @msg, "kill by signal ".($? & 127) if ($? & 127);
        push @msg, "core dumped" if ($? & 128);
        push @msg, "exit code ".($? >> 8) if $? >> 8;
    }
    die join ", ", @msg;
}

xsystem('rm -rf tfiles');
xsystem('mkdir tfiles');

my $service = Ubic::Service::Memcached->new({
    port => $port,
    maxsize => 10,
    verbose => 2,
    logfile => 'tfiles/memcached-test.log',
    pidfile => 'tfiles/memcached-test.pid',
    ubic_log => 'tfiles/ubic.log',
    user => $ENV{LOGNAME},
});

$service->start;
is($service->status, 'running', 'start works');

my $memcached = Cache::Memcached->new({
    servers => ["127.0.0.1:$port"],
});
$memcached->set('key1', 'value1');
is($memcached->get('key1'), 'value1', 'memcached responded');

$service->stop;
is($service->status, 'not running', 'stop works');

is($memcached->get('key1'), undef, 'memcached is down');

chomp(my $wc = qx(wc -l tfiles/memcached-test.log | awk '{print \$1}'));
cmp_ok($wc, '>', 10, 'log created and contains some data');

open my $fh, '<', 'tfiles/memcached-test.log' or die "Can't open log: $!";
my $log_content = do { local $/; <$fh> };
like($log_content, qr/set key1/, 'log contains memcached events');

is($service->port, $port, 'port method');

# TODO - check more thoroughly start/stop return values

