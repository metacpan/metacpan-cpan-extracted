use strict;
use warnings;
use utf8;
use Test::More;

use Test::Power;

sub foo { 3 }
expect { foo() == 3 };

done_testing;

