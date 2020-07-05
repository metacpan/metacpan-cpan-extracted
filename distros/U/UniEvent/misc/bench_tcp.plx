#!/usr/bin/env perl
use 5.012;
use warnings;
use lib 't/lib';
use MyTest;

XS::Loader::load('MyTest');
$SIG{PIPE} = 'IGNORE';

my $conns = shift(@ARGV) || 1;
my $len  = shift(@ARGV) || 10;
my $smp;
$smp = 1 if $conns =~ s/^\@//;
my $per_smp;
$per_smp = $1 if $conns =~ s/:(\d+)$//;
$per_smp ||= 1;

my $l = UE::Loop->default;
my $port = 51645;

if (my $pid = fork()) {
    say "starting server $$";
    MyTest::BenchTcp::start_server($port, $len);
} else {
    say "starting clients $$";
    $0 = "$0 (client)";
    select undef, undef, undef, 0.1;
    
    if ($smp) {
        for (1..$conns) {
            next if fork();
            MyTest::BenchTcp::start_client($port, "x" x $len) for 1..$per_smp;
            last;
        }
    } else {
        MyTest::BenchTcp::start_client($port, "x" x $len) for 1..$conns;
    }
}

$l->run;

say "END $$";
