#!/usr/bin/perl -w
use strict;
use warnings;
use Test::Builder::Tester;
use Test::More tests => 17;
use Data::Dumper;
use WWW::Mechanize;

use lib qw{lib};
use Test::MonitorSites;

my $cwd = `pwd`;
chomp($cwd);
my $config_file = "$cwd/t/testsuite_addtl.ini";
my $tester = Test::MonitorSites->new( { 'config_file' => $config_file } );
# diag('We\'re using as our config file: ');
# diag("     " . $config_file);

# END:
# {
  # print STDERR Dumper(\$tester);
  # print "That's it folks!\n"
# }

test_out("ok 1 - Successfully linked to http://www.perlmonks.com.",
   "ok 2 -  . . . and found expected content at http://www.perlmonks.com");

my $results = $tester->test_sites();

test_test( name => "Test suite produced the expected successes and errors.",
       skip_out => 1 );

my $test_output = '/tmp/test_sites_output_addtl_ok';
my $test_diagnostics = '/tmp/test_sites_output_addtl_diag';

my ($site,$test_number);
my $ok = 0;
my $not_ok = 0;
my $skip = 0;
my $todo = 0;
open('TESTS','<',$test_output);
while(<TESTS>){
  if(m/^ok/){ $ok++; }
  if(m/^not ok/){ $not_ok++; }
  if(m/# SKIP/){ $skip++; }
  if(m/^# TODO/){ $todo++; }
  if(m/- Successfully linked/){ 
    $test_number = $_;
    $test_number =~ s/ - Succ.*$//;
    $test_number =~ s/^.*ok //;
    $test_number = $test_number + 1;
    $site = $_;
    $site =~ s/^.*linked to //;
    if($site !~ m/example.com/) {
      like($_,qr/^ok /,"Successfully linked to $site");
    } else {
      like($_,qr/^not ok /,"Not able to find non-existent site: $site");
    }
  }
  if(m/$test_number/ && m/found expected content/){
    if($site !~ m/example.com/) {
      like($_,qr/^ok/,"  .  .  .  and found expected content for $site");
    } else {
      like($_,qr/^not ok/,"  .  .  .  and did not find expected content for non-existent site: $site");
    }
  }
  if(m/checked all links/){
    like($_,qr/ok/,"  .  .  .  checked all links on this page");
  }
  if(m/html content is valid/){
    like($_,qr/ok/,"  .  .  .  and the validity of the html code was tested");
  }
}
close('TESTS');

like($tester->{'error'},qr/there were no critical_failures/,'All tests passed, no text message sent');
# like($tester->{'error'},qr/Configuration file disabled email dispatch of results log./,'Configuration file set send_summary = 0, no summary sent');
# like($tester->{'error'},qr/Configuration file disabled email dispatch of diagnostic log./,'Configuration file set send_diagnostics = 0, so diagnostics not  sent');
# like($tester->{'error'},qr//,'');

test_out("ok 1 - Twelve is twelve.",
         "not ok 2 - Twelve is thirteen.");
$tester->_test_tests();
test_test( name => 'Basic tests seem to work.',
           skip_err => 1 );

my $log = $tester->_return_result_log();
like($log,qr/tmp\/test_sites_output_addtl/,'Seems to return the correct result_log');

$tester->{'error'} = undef;
$tester->{'config'}->delete('global.results_recipients');
  
test_out('');
$tester->test_sites();
  
test_test( name => "Test suite run without results_recipient defined.",
         skip_out => 1 );
  
like($tester->{'error'},qr/no results_recipient defined/,'No results_recipient defined, so no email will be sent.');

TODO:
{
  local $TODO = "On the bleeding edge of development . . . ";
}

# diag("Pierre requested report on all success.");
$config_file = "$cwd/t/testsuite_all_ok.ini";
$tester = Test::MonitorSites->new( { 'config_file' => $config_file } );
  
test_out("ok 1 - Successfully linked to http://www.perlmonks.com.",
  "ok 2 -  . . . and found expected content at http://www.perlmonks.com",
  "ok 3 - Successfully linked to http://validator.w3.org/.",
  "ok 4 -  . . . and found expected content at http://validator.w3.org/",
  "ok 5 - Successfully linked to http://www.cpan.org.",
  "ok 6 -  . . . and found expected content at http://www.cpan.org",
  "ok 7 - Successfully linked to http://www.campaignfoundations.com.",
  "ok 8 -  . . . and found expected content at http://www.campaignfoundations.com");

$tester->test_sites();
  
test_test( name => "Test suite ran without any critical errors", 
        skip_out => 1 );

TODO:
{
  local $TODO = "On the bleeding edge, no critical error report.";
}

# exit;
  
is($tester->{'result'}->{'critical_errors'},0,'No critical errors found.');
is($tester->{'result'}->{'servers_with_failures'},0,'No servers had errors.');
is($tester->{'result'}->{'tests'},8,'Eight tests were run.');
is($tester->{'result'}->{'sites'},4,'Four sites were tested.');
is($tester->{'result'}->{'ips'},4,'Sites on four IPs were tested.');
is($tester->{'result'}->{'message'},'Tests: 8, IPs: 4, Sites: 4, CFs: 0; No critical errors found.','Tests: 8, IPs: 4, Sites: 4, CFs: 0; No critical errors found.');

TODO:
{
  local $TODO = "On the bleeding edge of development . . . ";
}

1;

