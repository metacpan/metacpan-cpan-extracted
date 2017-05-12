use strict;
use warnings;
use Test::More tests => 2;
use UUID::FFI;

ok !!(UUID::FFI->new_null  ->is_null), 'is_null ~> true ';
ok  !(UUID::FFI->new_random->is_null), 'is_null ~> false';
