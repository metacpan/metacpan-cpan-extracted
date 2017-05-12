use strict;
local $^W = 1;
our $jobname;
require './t/defs.pm';
require Combine::Config;
use Cwd;

#Test that jobspecific config-file is generated OK

use Test::More tests => 1 ;

system("perl  \"-Iblib/lib\" blib/script/combineINIT --baseconfig ./blib/conf/ --jobname $jobname > /dev/null 2> /dev/null");
Combine::Config::Init($jobname,getcwd . '/blib/conf');

is(Combine::Config::Get('doCheckRecord'),0,'doCheckRecord=0');

#Test removed - default for useTidy changed to 0
#eval {require HTML::Tidy;};
#if ($@) {
#   is(Combine::Config::Get('useTidy'),0,'useTidy=0');
#} else {
#   is(Combine::Config::Get('useTidy'),1,'useTidy=1');
#}





