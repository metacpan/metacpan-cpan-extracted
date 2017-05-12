#!perl -T
# $Id: /tree-xpathengine/trunk/t/pod-coverage.t 21 2006-02-13T10:47:57.335542Z mrodrigu  $

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok();
