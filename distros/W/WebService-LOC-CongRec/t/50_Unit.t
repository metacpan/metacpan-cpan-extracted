use warnings;

use lib 't/lib';
use Test::Class;
#use Devel::Cover qw(-silent 1);

use WebService::LOC::CongRec::DayTest;
use WebService::LOC::CongRec::PageTest;
use WebService::LOC::CongRec::UtilTest;

Test::Class->runtests();
