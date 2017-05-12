# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl lib-deep.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
no warnings 'once';

use Test::More 'no_plan';
BEGIN { require_ok('lib::deep') };
local *na_path = \&lib::deep::path_need_canonize;
ok( na_path('.') );
ok( na_path('..') );
ok( na_path('a/..') );
ok( na_path('/a/..') );
ok( na_path('a/.') );
ok( na_path('/a/.') );


ok( na_path('a') );
ok( na_path('a123/b') );
ok( na_path('a123/.c') );
ok( na_path('/a/./b') );
ok( na_path('/a/../c') );

if ( $lib::deep::is_unix ){
    ok( !na_path( '/a/b/c/'));
}
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

