use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
ok(ref(nv_info()) eq 'HASH', 'nv_info returns a hashref');
ok(exists nv_info()->{type}, 'nv_info contains a type field');
ok(nv_info()->{size} > 0, 'nv_info size is positive');
