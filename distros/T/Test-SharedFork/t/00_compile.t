use strict;
use Test::More tests => 1;

diag "Test::Builder::VERSION: $Test::Builder::VERSION";

BEGIN { use_ok 'Test::SharedFork' }
