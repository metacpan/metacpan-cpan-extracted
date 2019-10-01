#!/usr/bin/env perl
use warnings;
use strict;
use XAO::TestUtils;

eval "use XAO::ImageCache";
if($@) { die "Can't load XAO::ImageCache - call as ``perl -Mblib $0'' ($@)\n" }

if(@ARGV) {
    XAO::TestUtils::xao_test(@ARGV);
}
else {
    XAO::TestUtils::xao_test_all('testcases::ImageCache');
}
