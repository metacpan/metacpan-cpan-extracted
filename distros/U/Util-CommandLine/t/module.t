use strict;
use warnings;

use Test::Most;

use constant MODULE => 'Util::CommandLine';

BEGIN { use_ok(MODULE); }
require_ok(MODULE);

done_testing;
