#Testing that conf-files exists and create copy of conf in blib
use strict;
local $^W = 1;

our $jobname;
require './t/defs.pm';
print "1..2\n";
my $i=1;

require Combine::Config;
use Cwd;
Combine::Config::Init($jobname,getcwd . '/blib/conf');
if (Combine::Config::Get('baseConfigDir') eq getcwd . '/blib/conf') {
  print "ok $i\n";
} else {print "not ok $i\n";}
$i++;

if (Combine::Config::Get('configDir') eq getcwd . '/blib/conf/' . $jobname) {
  print "ok $i\n";
} else {print "not ok $i\n";}
$i++;
