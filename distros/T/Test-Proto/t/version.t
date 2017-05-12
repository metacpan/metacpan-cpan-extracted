use strict;
use warnings;
use Test::More;

use Test::Proto::Base;
use Test::Proto;

is($Test::Proto::Base::VERSION, $Test::Proto::VERSION, 'Two sources of VERSION must be in sync');

done_testing;
