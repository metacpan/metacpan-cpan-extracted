#Tests the code in SubTest'd tap format.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Frobinate::Test;

Frobinate::Test->testcode->run();

#print Frobinate::Test->testcode->to_s;

