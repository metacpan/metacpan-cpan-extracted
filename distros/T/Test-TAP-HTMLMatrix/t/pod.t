#!perl -T

use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
plan skip_all => "Test::Pod is a little too draconic for my taste" unless $ENV{BITE_THE_BULLET};
all_pod_files_ok();
