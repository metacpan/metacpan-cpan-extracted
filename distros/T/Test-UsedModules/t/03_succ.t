#!perl

use strict;
use warnings;
use utf8;
use FindBin;
push @INC, "$FindBin::Bin/resource/lib";
use Test::UsedModules;

use Test::More;

my @test_modules = glob "t/resource/lib/Test/UsedModules/Succ/*";
foreach my $lib (@test_modules) {
    if ($lib =~ /Succ\d*.pm/) {
        require "Test/UsedModules/$&";
    }
    used_modules_ok($lib);
}

done_testing;
