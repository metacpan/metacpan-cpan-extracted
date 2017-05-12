#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 20;
use Data::Dumper;
use WWW::Mechanize;

use lib qw{lib};
use Test::MonitorSites;

my $cwd = `pwd`;
chomp($cwd);
my $config_file = "$cwd/t/testsuite_report_by_ip.ini";
my $tester = Test::MonitorSites->new( { 'config_file' => $config_file } );
$tester->test_sites();

1;

