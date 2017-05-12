use strict;
use warnings;
use lib 't/lib';

# Rename - test that the rename feature works

use MyTest::Rename;

is_true(1, 'is_true() is a renamed ok()');

equal("foo", "foo", 'equal() is a renamed is()');

ok('ok() is a renamed pass()');

done_testing();
