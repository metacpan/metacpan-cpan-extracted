#!/usr/bin/env perl -w

use strict;
use Test::More;

# Ensure a recent version of Test::Pod
eval "use Test::Pod 1.22; 1"
	or plan skip_all => "Test::Pod 1.22 required for testing POD";

all_pod_files_ok();
exit;
require Test::NoWarnings;
