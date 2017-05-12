#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 7;
# use Test::Mail;

use lib qw{lib};
use Test::MonitorSites;
# my $logfile = 't/testmail.output';
# my $tm = Test::Mail->new( logfile => $logfile );
# $tm->accept();
my $tester = Test::MonitorSites->new({
  'config_file' => 't/emailtest.ini',
      });

my $results = $tester->test_sites();

isa_ok($tester,'Test::MonitorSites');
can_ok($tester,'email');
can_ok($tester,'sms');


