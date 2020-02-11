package main;

use strict;
use warnings;

use Test2::Tools::LoadModule;

load_module_or_skip_all 'Test::Pod' => 1.00;

all_pod_files_ok();

1;

# ex: set textwidth=72 :
