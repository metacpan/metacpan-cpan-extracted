#!perl -T
# $Id: /tree-xpathengine/trunk/t/pod.t 21 2006-02-13T10:47:57.335542Z mrodrigu  $

use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
all_pod_files_ok();
