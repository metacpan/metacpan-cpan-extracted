use strict;
use warnings;
use Test::More;

require_ok('enum::prefix');

use enum::prefix BUG_ => qw(STATUS FIXED REOPEND CLOSED);

ok( BUG_FIXED == 0, "index");
ok( BUG_REOPEND == 1, "index");
ok( BUG_CLOSED == 2, "index");
ok( BUG_STATUS 0 eq 'FIXED' , "name");
ok( BUG_STATUS 1 eq 'REOPEND' , "name");
ok( BUG_STATUS 2 eq 'CLOSED' , "name");
done_testing;
