package MyTest::TestKitIncludingTestKit;

use strict;
use warnings;

use Test::Kit;

include 'MyTest::Basic' => { rename => { pass => 'foo' } };

include 'MyTest::Simple';

include 'MyTest::Rename' => { exclude => [ 'ok' ] };

1;
