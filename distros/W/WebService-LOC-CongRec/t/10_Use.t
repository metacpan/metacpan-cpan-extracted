use warnings;

use lib 't/lib';
use Test::More tests => 3;

BEGIN { use_ok('WebService::LOC::CongRec::Day') };
BEGIN { use_ok('WebService::LOC::CongRec::Page') };
BEGIN { use_ok('WebService::LOC::CongRec::Util') };
