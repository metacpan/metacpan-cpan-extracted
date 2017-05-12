#!/usr/bin/env perl

use v5.16.3;
use warnings;
use Getopt::Long qw/:config no_ignore_case bundling/;
use Path::Tiny;
use WebService::LogicMonitor;
use Try::Tiny;

my $hostname;
my $debug;

my $lm = WebService::LogicMonitor->new(
    username => $ENV{LOGICMONITOR_USER},
    password => $ENV{LOGICMONITOR_PASS},
    company  => $ENV{LOGICMONITOR_COMPANY},
);

GetOptions
  'debug|d!' => \$debug,
  'host|h=s' => \$hostname,
  or die "Commandline error\n";

if ($ENV{LOGICMONITOR_DEBUG} || $debug) {
    require Log::Any::Adapter;
    Log::Any::Adapter->set('Stderr');
}

if (!$hostname) {
    die "You must specify a hostname!\n";
}

say "\nChecking $hostname...";
my $host = try {
    $lm->get_host($hostname);
}
catch {
    say "Could not find host: $_";
};

use DDP;
p $host;

