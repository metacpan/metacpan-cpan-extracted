use strict;
use warnings;
use lib 't/lib';

# From Module - test that Test::Kit works in packages other than main

use MyTest::FromModule;

MyTest::FromModule::from_module_ok();

MyTest::FromModule::from_module_done_testing();
