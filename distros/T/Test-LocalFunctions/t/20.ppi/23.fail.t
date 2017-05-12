#!perl

use strict;
use warnings;
use utf8;
use FindBin;
push @INC, "$FindBin::Bin/../resource/lib";

use Test::LocalFunctions::PPI;

use Test::More;
use Test::Builder::Tester;

foreach my $lib (map{"t/resource/lib/Test/LocalFunctions/Fail$_.pm"} 1..3) {
    if ($lib =~ /Fail\d*.pm/) {
        require "Test/LocalFunctions/$&";
    }
    test_out "not ok 1 - $lib";
    local_functions_ok($lib);
    test_test (name => "testing local_functions_ok($lib)", skip_err => 1);
}

done_testing;
