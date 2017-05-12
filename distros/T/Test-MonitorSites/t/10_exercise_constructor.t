#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 49;
use Data::Dumper;
use WWW::Mechanize;

use lib qw{lib};
use Test::MonitorSites;

my $package = 'Test::MonitorSites';
foreach my $method ('new', 'test_sites', 'email', 'sms') {
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

$package = 'WWW::Mechanize';
foreach my $method ('new', 'content', 'get') {
  can_ok($package,$method);
}

END: {
#    print Dumper($tester->{'config'}->{'_DATA'});
;
}

is($tester->{'config'}->{'_FILE_NAME'},$config_file,"The object includes the correct configuration filename.");
like($tester->{'result_log'},qr/test_sites_output/,'It gives the configured result log file');

is($tester->{'config'}->param('global.MonitorSites_email'),'MonitorSites_test_constructor@example.com','The constructor returned the From: address defined in config file.');

my $agent = WWW::Mechanize->new();
my (@url,@expected);
foreach my $site (@{$tester->{'sites'}}){
  @url = @{$tester->{'config'}->{'_DATA'}->{"site_$site"}->{'url'}};
  @expected = @{$tester->{'config'}->{'_DATA'}->{"site_$site"}->{'expected_content'}};
  $agent->get($url[0]);
  like($url[0],qr/$site/,"Got correct url for $site.");
  if($site =~ m/example.com/){
    unlike($agent->content(),qr/$expected[0]/,"  .  .  .  and did not find expected content on non-existent site");
  } else {
    like($agent->content(),qr/$expected[0]/,"  .  .  .  and found expected content");
  }
}

$tester = Test::MonitorSites->new();
isnt($tester->{'config'}->{'_FILE_NAME'},$config_file,"This object does not include the correct configuration filename.");
like($tester->{'error'},qr/config_file was not set in the constructor/,'But an appropriate error was thrown for a missing configuration hash.');

$tester = Test::MonitorSites->new( { 'config_file' => undef } );
isnt($tester->{'config'}->{'_FILE_NAME'},$config_file,"This object does not include the correct configuration filename.");
like($tester->{'error'},qr/config_file was not set in the constructor/,'But an appropriate error was thrown for an undefined configuration file.');

$config_file = "$cwd/t/non_existant_testsuite.ini";
$tester = Test::MonitorSites->new( { 'config_file' => $config_file } );
isnt($tester->{'config'}->{'_FILE_NAME'},$config_file,"This object does not include the correct configuration filename.");
like($tester->{'error'},qr/config_file was not found, or was empty/,'But an appropriate error is thrown by an invalid configuration file.');

$config_file = "$cwd/t/empty_test_suite.ini";
$tester = Test::MonitorSites->new( { 'config_file' => $config_file } );
isnt($tester->{'config'}->{'_FILE_NAME'},$config_file,"This object does not include the empty configuration file.");
like($tester->{'error'},qr/No configuration data is available./,'And an appropriate error is thrown for this empty file.');

$config_file = "$cwd/t/incomplete_test_suite.ini";
$tester = Test::MonitorSites->new( { 'config_file' => $config_file } );
is($tester->{'config'}->{'_FILE_NAME'},$config_file,"This object does include the incomplete configuration file.");
# is($tester->{'error'},undef,'And the empty file error is not thrown.');
unlike($tester->{'error'},qr/No configuration data is available./,'And the empty file error is not thrown.');
like($tester->{'result_log'},qr/Test_MonitorSites_result.log/,'It gives us the default result log file');

$tester = Test::MonitorSites->new( { 'config_file' => 't/testsuite_exercise_defaults.ini' } );
isnt($tester->{'config'}->param('global.MonitorSites_email'),'',"This object does not include a blank From: address.");
like($tester->{'error'},qr/Configuration fails to define global.MonitorSites_email for From: line./,'But an appropriate error is thrown saying the return email was left undefined in the configuration.');
like($tester->{'config'}->param('global.MonitorSites_email'),qr/MonitorSites\@example.net/,' . . . and the default From: address is set in the constructor.');

is($tester->{'result'}->{'ips'},0,'Count of IPs properly initiated.');
is($tester->{'result'}->{'critical_errors'},0,'Count of critical errors properly initiated');
is($tester->{'result'}->{'servers_with_failures'},0,'Count of servers with failures properly initiated.');
is($tester->{'result'}->{'tests'},0,'Count of tests properly initiated.');
is($tester->{'result'}->{'sites'},0,'Count of sites properly initiated.');

is($tester->{'config'}->param('global.report_success'),0,"This object set global.report_success to false value by default.");
is($tester->{'config'}->param('global.MonitorSites_subject'),'Critical Failures','->sms() subject line set to default');
is($tester->{'config'}->param('global.MonitorSites_all_ok_subject'),'Servers All OK','->email() subjetc line set to default');

TODO:
{

  local $TODO = "";

  # $tester = Test::MonitorSites->new( { 'config_file' => undef } );
  # isnt($tester->{'config'}->{'_FILE_NAME'},$config_file,"This object does not include the correct configuration filename.");
  # like($tester->{'error'},qr/config_file was not set in the constructor/,'But an appropriate error was thrown for an undefined configuration file.');

}

1;
