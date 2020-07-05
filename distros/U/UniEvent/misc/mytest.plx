#!/usr/bin/env perl
use 5.012;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Benchmark qw/timethis timethese/;
use Data::Dumper qw/Dumper/;
use UniEvent;
use Devel::Peek;
use B::Concise;
use Socket ':all';
use Time::HiRes qw/time/;
use Net::SockAddr;
use Net::SSLeay;

$SIG{PIPE} = 'IGNORE';
my $l = UE::Loop->default;

say "START $$";

my $cnt;
my $h = UE::Check->new;
*UniEvent::Check::on_check = sub { ++$cnt };
$h->event_listener($h);

timethis(-1, sub {
    $h->call_now for 1..1000;
}) for 1..5;

say $cnt;
