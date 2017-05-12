use Test::More tests => 2;

use strict;
use warnings;

BEGIN {
    use_ok('Test::Uses');   
}

uses_ok(__FILE__, 'Test::More', "This test file uses Test::More");

1;
