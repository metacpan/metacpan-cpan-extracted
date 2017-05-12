# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WebService-Jamendo-RSS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Test;

BEGIN { plan tests => 1 };
use WebService::Jamendo::RSS;
ok(1); # If we made it this far, we're ok.

#########################
