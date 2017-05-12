#!/usr/bin/perl -w
use strict;
use warnings;
use Test::Builder::Tester;
use Test::More tests => 33;
use Data::Dumper;
use WWW::Mechanize;

use lib qw{lib};
use Test::MonitorSites;

my $package = 'Test::MonitorSites';
foreach my $method ('new', 'test_sites', 'email', 'sms', '_analyze_test_logs', '_test_tests', '_return_result_log', '_test_links', '_test_valid_html', '_test_site') {
  can_ok($package,$method);
}

my $cwd = `pwd`;
chomp($cwd);
my $config_file = "$cwd/t/testsuite.ini";
# diag('We\'re using as our config file: ');
# diag("     " . $config_file);
my $tester = Test::MonitorSites->new( { 'config_file' => $config_file } );
isa_ok($tester,'Test::MonitorSites');
isa_ok($tester->{'config'},'Config::Simple');
isa_ok($tester->{'agent'},'WWW::Mechanize');
isa_ok($tester->{'mech'},'Test::WWW::Mechanize');

$package = 'Config::Simple';
foreach my $method ('new', 'param', 'vars') {
  can_ok($package,$method);
}

test_out("ok 1 - Successfully linked to http://www.perlmonks.com.",
   "ok 2 -  . . . and found expected content at http://www.perlmonks.com",
   "not ok 3 - Successfully linked to http://www.example.com.",
   "not ok 4 -  . . . and found expected content at http://www.example.com",
   "ok 5 - Successfully linked to http://validator.w3.org/.",
   "ok 6 -  . . . and found expected content at http://validator.w3.org/",
   "ok 7 -  . . . linked to http://validator.w3.org/",
   "ok 8 -  . . . successfully checked all links for http://validator.w3.org/",
   "ok 9 -  . . . linked to http://validator.w3.org/",
   "ok 10 -  . . . html content is valid for http://validator.w3.org/",
   "ok 11 - Successfully linked to http://www.cpan.org.",
   "ok 12 -  . . . and found expected content at http://www.cpan.org",
   "ok 13 - Successfully linked to http://www.campaignfoundations.com.",
   "ok 14 -  . . . and found expected content at http://www.campaignfoundations.com");

my $results = $tester->test_sites();

test_test( name => "Test suite produced the expected successes and errors.",
       skip_out => 1 );

is(defined($results->{'sites'}),1,'The result returned a sites value');
is(ref $results->{'sites'},'ARRAY','The sites value is an array');
my $sites_count = @{$results->{'sites'}};
is($sites_count,5,'It includes the right number of sites');

my $test_output = '/tmp/test_sites_output_ok';
my $test_diagnostics = '/tmp/test_sites_output_diag';

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

# is(defined($result->{'sites'}),1,'');
# is(defined($result->{'sites'}),1,'');
# is(defined($result->{'sites'}),1,'');
# is(defined($result->{'sites'}),1,'');

1;

