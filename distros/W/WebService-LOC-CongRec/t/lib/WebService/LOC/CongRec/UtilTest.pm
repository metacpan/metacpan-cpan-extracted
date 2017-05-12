use warnings;

package WebService::LOC::CongRec::UtilTest;
use base 'WebService::LOC::CongRec::TestBase';
use WebService::LOC::CongRec::Util;

use Test::More;

sub getCongressFromYear_FirstYear : Test(1) {
    is(WebService::LOC::CongRec::Util->getCongressFromYear(1789), 1);
};

sub getCongressFromYear_SecondYear : Test(1) {
    is(WebService::LOC::CongRec::Util->getCongressFromYear(1790), 1);
};

sub getCongressFromYear_SecondCongress : Test(1) {
    is(WebService::LOC::CongRec::Util->getCongressFromYear(1791), 2);
};

sub getCongressFromYear_111 : Test(1) {
    is(WebService::LOC::CongRec::Util->getCongressFromYear(2010), 111);
};

sub getMonthNumberFromString : Test(1) {
    is(WebService::LOC::CongRec::Util->getMonthNumberFromString('July'), 7);
};

1;
