use strict;
local $^W = 1;
our $jobname;
require './t/defs.pm';
require Combine::Config;
use Cwd;

#Test that jobspecific config-file is generated OK

use Test::More tests => 1 ;

system("perl  \"-Iblib/lib\" blib/script/combineINIT --baseconfig ./blib/conf/ --jobname $jobname --topic ./conf/Topic_carnivor.txt > /dev/null 2> /dev/null");
Combine::Config::Init($jobname,getcwd . '/blib/conf');

is(Combine::Config::Get('doCheckRecord'),1,'doCheckRecord=1');

