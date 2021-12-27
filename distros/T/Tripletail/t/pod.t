#!perl -T
use strict;
use Test::More;

eval "use Test::Pod 1.14;";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;

eval "require Encode;";
plan skip_all => "Encode required for testing POD" if $@;

all_pod_files_ok(
    all_pod_files(), # 'blib' or 'lib'
    all_pod_files('doc'));
