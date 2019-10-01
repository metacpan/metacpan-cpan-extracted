#!/usr/bin/env perl
use warnings;
use strict;

eval "use XAO::TestUtils";
if($@) { die "Can't find XAO::Base - call as ``perl -Mblib $0'' ($@)\n" }

if(@ARGV) {
    XAO::TestUtils::xao_test(@ARGV);
}
else {
    XAO::TestUtils::xao_test_all('testcases::Catalogs');
}
