#!perl -w
use strict;
use Test::More tests => 3;

BEGIN { use_ok('WebService::Google::Sets', qw(get_large_gset get_gset) ) }

can_ok('WebService::Google::Sets', 'get_gset');
can_ok('WebService::Google::Sets', 'get_large_gset');
