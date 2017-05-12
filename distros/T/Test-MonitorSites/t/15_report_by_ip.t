#!/usr/bin/perl -w
use strict;
use warnings;
use Test::Builder::Tester;
use Test::More tests => 4;
use Data::Dumper;
use WWW::Mechanize;

use lib qw{lib};
use Test::MonitorSites;

my $cwd = `pwd`;
chomp($cwd);
my $config_file = "$cwd/t/testsuite_rpt_by_ip.ini";
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

# print Dumper(\$tester->{'sms_log'});

foreach my $log_msg (@{$tester->{'sms_log'}}) {
  if($log_msg =~ m/example.net/){
    like($log_msg,qr/1 critical errors at 0.0.0.0; incl 1 domains: NOK: www.example.com/,'report_by_ip is enabled, so sms critical failure reports are aggregated by ip.');
  }
}

@{$tester->{'sms_log'}} = [];
$tester->{'config'}->delete('global.report_by_ip');
# diag("report_by_ip is: " . $tester->{'config'}->param('global.report_by_ip'));
my $addtl_test_site = 'site_www.example.com';
# $tester->{'config'}->param($addtl_test_site.'.url','http://www.example.com');
# $tester->{'config'}->param($addtl_test_site.'.expected_content','No content to find on non-existent page');
test_out("ok 1","ok 2"); 
# print Dumper(\$tester->{'config'});
$tester->test_sites();
test_test( name => "Test suite produced its results",
       skip_out => 1 );

foreach my $log_msg (@{$tester->{'sms_log'}}) {
  if($log_msg =~ m/example.com/){
    like($log_msg,qr/www.example.com: Not OK: expected_content,/,'report_by_ip not defined, so sms sent for each critical failure at this ip.');
  }
}

TODO:
{
  local $TODO = "On the bleeding edge of development . . . ";
}

1;

