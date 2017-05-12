#!perl

use strict;
use warnings;
use utf8;
use FindBin;
push @INC, "$FindBin::Bin/resource/lib";
use Test::UsedModules;

use Test::More;
use Test::Builder::Tester;

my @test_modules = glob "t/resource/lib/Test/UsedModules/Fail/*";
foreach my $lib (@test_modules) {
    if ($lib =~ /Fail\d*.pm/) {
        require "Test/UsedModules/$&";
    }
    test_out "not ok 1 - $lib";
    used_modules_ok($lib);
    test_test (name => "testing used_modules_ok($lib)", skip_err => 1);
}

done_testing;
