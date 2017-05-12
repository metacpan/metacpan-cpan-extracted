#!perl
use strict;
use warnings;
use Test::More;
eval{ require Test::Pod; VERSION Test::Pod 1.00; import Test::Pod; };
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();

# $Id: pod.t 191 2007-12-31 15:27:08Z rmb1 $
