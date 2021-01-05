use strict;
use warnings;

use Test::More;

use lib 't/lib';

# things we're going to mock
use ScopedStrict::Mockee1;
use ScopedStrict::Mockee2;

# mock one of them in strict mode
use ScopedStrict::StrictMocker;
# this doesn't turn on strict mode, and tries to use ->mock(). It
# shouldn't crash
use ScopedStrict::NonStrictMocker;

# yay, we didn't crash!
pass "Using 'strict' mode in one module that we use didn't prevent ->mock()ing in another";
done_testing();
