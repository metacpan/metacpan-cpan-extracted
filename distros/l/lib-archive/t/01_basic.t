use strict;
use warnings;

use Test::More;

use version;

use lib::archive "arclib/VMod.tgz";

use VMod;
is(version->parse($VMod::VERSION), version->parse(1.0), 'version ok');

done_testing();
