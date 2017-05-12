#!/usr/bin/perl
# $Id: 01_pod.t 2 2008-10-20 09:56:47Z rjray $

use Test::More;

eval "use Test::Pod 1.00";

plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

all_pod_files_ok();

exit;
