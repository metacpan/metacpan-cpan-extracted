#!/usr/bin/perl

# $Id: 01_pod.t 19 2006-09-20 06:03:06Z  $

use Test::More;

eval "use Test::Pod 1.00";

plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

all_pod_files_ok();

exit;
