# test sources for POD syntax

use strict;
use warnings;

use Test::More;

eval {
    require Test::Pod;
    Test::Pod->VERSION(1.22);
    Test::Pod->import();
    1;
} or plan skip_all => 'Test::Pod (>=1.22) is required';

all_pod_files_ok(qw/ lib t /);
