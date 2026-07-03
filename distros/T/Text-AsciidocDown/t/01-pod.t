use strict;
use warnings;

use Test::More;

eval "use Test::Pod 1.41";
plan skip_all => 'Test::Pod 1.41 required for POD testing' if $@;

all_pod_files_ok();