#!/usr/bin/perl
use XAO::TestUtils;

use lib qw(testdata);

if(@ARGV) {
    XAO::TestUtils::xao_test(@ARGV);
}
else {
    XAO::TestUtils::xao_test_all('XAO::testcases::FS');
}
