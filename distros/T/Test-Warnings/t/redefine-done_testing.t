use strict;
use warnings;

BEGIN { $^W = 1 }

use Test::More;
use Test::Warnings;

pass('we can load Test::Warnings after Test::More and not see a redefinition warning');
done_testing;
