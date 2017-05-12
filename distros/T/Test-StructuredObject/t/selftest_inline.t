# Tests the code in linearized form.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Frobinate::Test;

Frobinate::Test->testcode->linearize->run();

# print Frobinate::Test->testcode->linearize->to_s;
