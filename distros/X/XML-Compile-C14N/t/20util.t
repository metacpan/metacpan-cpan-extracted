#!/usr/bin/env perl
# Test functions and constants provided by ::Util
use warnings;
use strict;

use Test::More tests => 8;

use XML::Compile::C14N::Util qw(:c14n :paths);

ok( is_canon_constant C14N_v10_NO_COMM);
ok( is_canon_constant C14N_v10_COMMENTS);
ok( is_canon_constant C14N_v11_NO_COMM);
ok( is_canon_constant C14N_v11_COMMENTS);
ok( is_canon_constant C14N_EXC_NO_COMM);
ok( is_canon_constant C14N_EXC_COMMENTS);
ok( is_canon_constant C14N_EXC_NS);
ok(!is_canon_constant 'http://something/else');

