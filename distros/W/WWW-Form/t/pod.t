#!perl -T

use File::Spec;
use lib File::Spec->catfile("t", "lib");
use CondTestMore;

eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
all_pod_files_ok();
