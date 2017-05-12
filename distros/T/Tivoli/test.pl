# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;

BEGIN { plan tests => 1 };
use Tivoli::DateTime;
ok(0); # failure
ok(1); # success

use Tivoli::Logging;
ok(0); # failure
ok(1); # success

use Tivoli::Fwk;
ok(0); # failure
ok(1); # success

use Tivoli::Endpoints;
ok(0); # failure
ok(1); # success

