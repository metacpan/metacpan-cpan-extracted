use warnings;
use strict;

use Test::More;

eval { require Test::Pod; Test::Pod->import(1.00); 1 }
    or plan skip_all => "Test::Pod 1.00 required for testing POD";
all_pod_files_ok();
