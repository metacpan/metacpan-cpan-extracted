#!/usr/bin/perl -w
use strict;
use warnings;
use Test::Builder::Tester;
use Test::More tests => 18;
use Data::Dumper;
use WWW::Mechanize;

use lib qw{lib};
use Test::MonitorSites;

my $cwd = `pwd`;
chomp($cwd);
my $config_file = "$cwd/t/testsuite_monitor_quietly.ini";
# diag('We\'re using as our config file: ');
# diag("     " . $config_file);
my $tester = Test::MonitorSites->new( { 'config_file' => $config_file } );

# END:
# {
  # print STDERR Dumper(\$tester);
  # print "That's it folks!\n"
# }

my $test_output = '/tmp/test_sites_output_addtl_ok';
my $test_diagnostics = '/tmp/test_sites_output_addtl_diag';

test_out("ok 1","ok 2"); 
# print Dumper(\$tester->{'config'});
$tester->test_sites();
test_test( name => "Test suite produced results",
       skip_out => 1 );

is($tester->{'config'}->param('global.send_summary'),undef,'The constructor leaves send_summary undefined, based on configuration');
is($tester->{'config'}->param('global.send_diagnostics'),undef,'The constructor leaves send_diagnostics undefined, based on configuration');
is($tester->{'config'}->param('global.report_success'),0,'The constructor sets report_success to false, based on configuration');
is($tester->{'config'}->param('global.report_by_ip'),1,'The constructor set report_by_ip as true, based on configuration');

like($tester->{'error'},qr/neither send_summary nor send_diagnostics were set to true/,'No email summary was sent.');


$tester = Test::MonitorSites->new( { 'config_file' => $config_file } );
$tester->{'error'} = '';
$tester->{'config'}->param('global.send_summary',1);
test_out("ok 1","ok 2"); 
# print Dumper(\$tester->{'config'});
$tester->test_sites();
test_test( name => "Test suite produced some more results",
       skip_out => 1 );

is($tester->{'config'}->param('global.send_summary'),1,'send_summary is now true');
is($tester->{'config'}->param('global.send_diagnostics'),undef,'The constructor leaves send_diagnostics undefined, based on configuration');
is($tester->{'config'}->param('global.report_success'),0,'The constructor sets report_success to false, based on configuration');
is($tester->{'config'}->param('global.report_by_ip'),1,'The constructor set report_by_ip as true, based on configuration');

unlike($tester->{'error'},qr/neither send_summary nor send_diagnostics were set to true/,'An email summary should have been sent.');

 
$tester = Test::MonitorSites->new( { 'config_file' => $config_file } );
$tester->{'error'} = '';
$tester->{'config'}->param('global.send_summary',0);
$tester->{'config'}->param('global.send_diagnostics',1);
test_out("ok 1","ok 2"); 
# print Dumper(\$tester->{'config'});
$tester->test_sites();
test_test( name => "Test suite produced some more results",
       skip_out => 1 );

is($tester->{'config'}->param('global.send_summary'),0,'send_summary is false again');
is($tester->{'config'}->param('global.send_diagnostics'),1,'send_diagnostics is now true');
is($tester->{'config'}->param('global.report_success'),0,'The constructor sets report_success to false, based on configuration');
is($tester->{'config'}->param('global.report_by_ip'),1,'The constructor set report_by_ip as true, based on configuration');

unlike($tester->{'error'},qr/neither send_summary nor send_diagnostics were set to true/,'An email summary should have been sent.');


TODO:
{
  local $TODO = "On the bleeding edge of development . . . ";
}

1;

