package MyTest::ImportCheck;

use strict;
use warnings;

sub import { "foo" }

use Test::Kit;

include 'Test::More';

1;
