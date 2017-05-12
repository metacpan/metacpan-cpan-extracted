use strict;
use Test::More tests => 3;

require Test::Lib;

ok !eval { Test::Lib->import; 1 }, 'tlib import dies to find t/lib more than 5 levels up';
like $@, qr{^unable to find t/lib directory in }, 'error message correct';
ok !eval { require tlib_test; 1 }, 'nothing added to @INC';


1;
