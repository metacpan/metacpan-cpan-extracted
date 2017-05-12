use strict;

use Test::More tests =>8;

use URL::Check;
use File::Basename qw/dirname/;



#check simple config with errors
my $configFile = "t/resources/config/various-check-type.txt";
ok(-f $configFile, "checking presence of $configFile");

URL::Check::readConfig($configFile);
my %config = %URL::Check::config;

is($config{urls}[0]{check}{overtime}, 30000, "check overtime status");
is(scalar(@{$config{urls}[2]{check}{contains}}), 2, "2 contains test");


URL::Check::run();

my %report = URL::Check::errorReport();
ok(%report, "error report is not empty");

my $output ;
{
  local *STDOUT ;
  open STDOUT, ">", \$output or die "cannot redirect STDOUT to variable\n";
  URL::Check::submitReport(%report);
}

like($output, qr/http:\/\/www.google.com : overtime > 5/, "google is overtime (5ms!)");
unlike($output, qr/http:\/\/www.apple.com/, "enough time to get www.apple.com");

like($output, qr/http:\/\/www.apple.ch : does not contains /, "apple does not advertise microsoft");
unlike($output, qr/http:\/\/www.google.ch/, "google page should contains character 'o'");

