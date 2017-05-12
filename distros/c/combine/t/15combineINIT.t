use strict;
local $^W = 1;
our $jobname;
require './t/defs.pm';
require Combine::Config;
use Cwd;

#Test that jobspecific config-file is generated OK

use Test::More tests => 2 ;

my $myconf = '/tmp/combineTestMyConf.cfg';
open(MYCONF,">$myconf");
print MYCONF " doCheckRecord = 1\n";
print MYCONF " useTidy = 0\n";
close(MYCONF);

system("perl  \"-Iblib/lib\" blib/script/combineINIT --baseconfig ./blib/conf/ --jobname $jobname --myconf $myconf > /dev/null 2> /dev/null");
Combine::Config::Init($jobname,getcwd . '/blib/conf');

is(Combine::Config::Get('doCheckRecord'),1,'doCheckRecord=1');
is(Combine::Config::Get('useTidy'),0,'useTidy=0');

system("rm $myconf");
