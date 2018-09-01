use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use version;

use lib::archive "$Bin/arclib/*.tgz", "$Bin/arclib/VMod4-7.0.tar.gz";

use_ok('VMod');
is(version->parse($VMod::VERSION), version->parse(1.0), 'version ok');

use_ok('VMod2');
is(version->parse($VMod2::VERSION), version->parse(2.0), 'version ok');

use_ok('VMod3');
is(version->parse($VMod3::VERSION), version->parse(3.0), 'version ok');

use_ok('VMod4');
is(version->parse($VMod4::VERSION), version->parse(6.0), 'version ok');

done_testing();
