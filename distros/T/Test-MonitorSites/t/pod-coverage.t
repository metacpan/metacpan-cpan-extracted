#!/usr/bin/perl -wT
use strict;
use warnings;
use lib qw{lib};

use Test::More;
SKIP:
{
    eval "use Test::Pod::Coverage 1.04";
    if($@){
    plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage";
    } else {
        plan tests => 1;
    }
    skip("This test does not work yet",1);
    all_pod_coverage_ok();
}
