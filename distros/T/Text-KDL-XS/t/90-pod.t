use strict;
use warnings;
use Test::More;

eval { require Test::Pod; Test::Pod->import; 1 }
    or plan skip_all => 'Test::Pod required for testing POD';

all_pod_files_ok('lib');
